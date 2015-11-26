require_dependency "resource_management/application_controller"

module ResourceManagement
  class DomainAdminController < ApplicationController
    before_filter :set_usage_stage, :only => [:index,:show_area]

    def index
      stats = ResourceManagement::Resource.
                 where(:domain_id => @scoped_domain_id).
                 where.not(project_id: nil).
                 group("service,name").
                 pluck("service,name,SUM(current_quota),SUM(approved_quota),SUM(usage)")
      
      stats.each do |stat|
        service = stat[0]
        name = stat[1]
        projects_current_quota = stat[2]
        puts service
        puts name
        domain_quota = ResourceManagement::Resource.where(:domain_id => @scoped_domain_id, :project_id => nil, :service => service, :name => name)
        next if domain_quota.blank?
        puts "#####"
        puts domain_quota[0].approved_quota * @usage_stage[:danger]
        puts projects_current_quota
        if  projects_current_quota > domain_quota[0].approved_quota * @usage_stage[:danger] 

        end
#        puts stat[1]
#        domain_current_quota = stat[2]
#        domain_quota_value = 
#        domain_usage = 
#        puts domain_usage
      end
    end

    def show_area
      @area = params.require(:area).to_sym
      # which services belong to this area?
      @area_services = ResourceManagement::Resource::KNOWN_RESOURCES.select { |res| res[:area] == @area }.map { |res| res[:service] }.uniq
      # load domain quota for these services
      @domain_quotas = ResourceManagement::Resource.where(:domain_id => @scoped_domain_id, :project_id => nil, :service => @area_services)
     # raise
      # load quota and usage for all projects within these domain
      get_resource_status()
      pp @resource_status


     # raise
    end


    def resource_request
      @resource_type = params[:resource_type]
      @level = params[:level]
    end

    def details
      @resource_type = params[:resource_type]
      @level = params[:level]
    end

    private

    def set_usage_stage
      @usage_stage = { :danger => 1.0, :warning => 0.8 }
    end

    def get_resource_status()

      # get data for currently existing quota 
      stats = ResourceManagement::Resource.
                where(:domain_id => @scoped_domain_id, :service => @area_services).
                where.not(project_id: nil).
                group("service,name").
                pluck("service,name,SUM(current_quota)")

      # get unlimited quotas
      unlimited = ResourceManagement::Resource.
          where(:domain_id => @scoped_domain_id, :service => @area_services).
          where.not(project_id: nil).
          where(:current_quota => -1) 
pp unlimited
      @resource_status = {}
      stats.each do |stat|
        service, name, current_project_quota_sum = *stat
        domain_service_quota = @domain_quotas.find { |q| q.service == service && q.name == name }
        # search for unlimited current quotas
        unlimited_project_quota_found = unlimited.find{|q| q.service == service && q.name == name}
       
        active_project_quota = false
        if unlimited_project_quota_found.nil?
          active_project_quota = true
        end
        # when no domain quota exists yet, use an empty mock object
        domain_service_quota ||= ResourceManagement::Resource.new(
          service: service, name: name, approved_quota: -1,
        )
        @resource_status[service.to_sym] ||= []
        @resource_status[service.to_sym] << { 
          :name => name,
          :current_project_quota_sum => current_project_quota_sum,
          :active_project_quota => active_project_quota,
          :domain_quota => domain_service_quota,
        } 
      end
    end
  end
end
