module EmailService
  class TemplatedEmailsController < ::EmailService::ApplicationController
    include AwsSesHelper
    include EmailHelper

    def index

      @all_emails = list_verified_identities("EmailAddress")
      @verified_emails = get_verified_emails_by_status(@all_emails, "Success")
      @pending_emails  = get_verified_emails_by_status(@all_emails, "Pending")
      @failed_emails   = get_verified_emails_by_status(@all_emails, "Failed")

      @configsets = get_configset

    end


    def new
      @all_emails = list_verified_identities("EmailAddress")
      @verified_emails = get_verified_emails_by_status(@all_emails, "Success")
      @pending_emails  = get_verified_emails_by_status(@all_emails, "Pending")
      @failed_emails   = get_verified_emails_by_status(@all_emails, "Failed")

      @configsets = get_configset
      @templates = list_templates
      @verified_emails_collection = get_verified_email_collection(@verified_emails)
      @templates_collection = get_templates_collection(@templates) if @templates && !@templates.empty?

    end

    def create

      @templated_email = new_templated_email(templated_email_params)  
      result = email_to_array(@templated_email)
      status = send_templated_email(result)
      
      if status == "success"
        msg = "eMail sent successfully"
        flash[:success] = msg 
      else 
        msg = "error occured: #{status}"   
        flash[:error] = msg 
      end
      logger.debug "CRONUS DEBUG: (controller) #{msg}"
      redirect_to plugin('email_service').emails_path

    end

    def templated_email_params
      unless params['email'].blank?
        templated_email = params.clone.fetch('email', {})
        return templated_email
      end
      return {}
    end


  end
end
