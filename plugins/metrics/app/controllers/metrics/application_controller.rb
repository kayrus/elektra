# frozen_string_literal: true

module Metrics
  class ApplicationController < DashboardController
    authorization_context 'metrics'
    authorization_required

    def index
      enforce_permissions('metrics:application_list')
    end

    def maia
      redirect_to "https://maia.#{current_region}.cloud.sap/#{@scoped_domain_name}?x-auth-token=#{current_user.token}"
    end
    
    def server_statistics
      cpu_usage_avarage = services_ng.metrics.cpu_usage_avarage(params.require('server_name'))
      
      render json: { 
        cpu_usage_avarage: [{
          key: cpu_usage_avarage.metric['vmware_name'],
          values: cpu_usage_avarage.values
        }]
      }
    end
  end
end
