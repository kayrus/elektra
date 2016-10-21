require 'spec_helper'
require_relative '../factories/factories'

describe KeyManager::SecretsController, type: :controller do
  routes { KeyManager::Engine.routes }

  default_params = {domain_id: AuthenticationStub.domain_id, project_id: AuthenticationStub.project_id}

  before(:all) do
    FriendlyIdEntry.find_or_create_entry('Domain',nil,default_params[:domain_id],'default')
    FriendlyIdEntry.find_or_create_entry('Project',default_params[:domain_id],default_params[:project_id],default_params[:project_id])
  end

  before :each do
    stub_authentication
    stub_admin_services

    identity_driver = double('identity_service_driver').as_null_object
    keymanager_service = double('keymanager_service').as_null_object

    allow_any_instance_of(ServiceLayer::IdentityService).to receive(:driver).and_return(identity_driver)
    allow_any_instance_of(ServiceLayer::KeyManagerService).to receive(:service).and_return(keymanager_service)
    allow(UserProfile).to receive(:tou_accepted?).and_return(true)
  end

  describe "GET 'index'" do

    before :each do
      @secret = ::KeyManager::FakeFactory.new.secret(secret_ref: "https://localhost:443/v1/secrets/4373e881-2f12-4c9f-b236-1e39738fae40")
      allow_any_instance_of(ServiceLayer::KeyManagerService).to receive(:secrets).and_return({elements: [@secret], total_elements: 1})
    end

    it "returns http success and renders the right template" do
      get :index, default_params
      expect(response).to be_success
      expect(response).to render_template(:index)
    end

  end

  describe "GET 'show'" do

    before :each do
      @secret = ::KeyManager::FakeFactory.new.secret(secret_ref: "https://localhost:443/v1/secrets/4373e881-2f12-4c9f-b236-1e39738fae41")
      allow_any_instance_of(ServiceLayer::KeyManagerService).to receive(:secret).with(@secret.uuid).and_return(@secret)
    end

    it "returns http success and renders the right template" do
      get :show, default_params.merge!({id: @secret.uuid})
      expect(response).to be_success
      expect(response).to render_template(:show)
    end

  end

  describe "GET 'new'" do

    it "returns http success and renders the right template" do
      get :new, default_params
      expect(response).to be_success
      expect(response).to render_template(:new)
    end

  end

  describe "GET xhr 'type_update'" do

    it "returns http success" do
      xhr :get, :type_update, default_params
      expect(response).to be_success
      expect(response).to render_template(:type_update)
    end

  end

  describe "GET 'payload'" do

    before :each do
      @secret = ::KeyManager::FakeFactory.new.secret(secret_ref: "https://localhost:443/v1/secrets/4373e881-2f12-4c9f-b236-1e39738fae42")
      allow_any_instance_of(ServiceLayer::KeyManagerService).to receive(:secret).with(@secret.uuid).and_return(@secret)
      allow_any_instance_of(RestClient::Request).to receive(:execute).and_return('test')
    end

    it "returns http success" do
      get :payload, default_params.merge({id: @secret.uuid})
      expect(response).to be_success
      expect(response).to render_template(layout: false)
      expect(response).to render_template(partial: false)
    end

  end

  describe "GET 'create'" do

    it "returns http success and renders the new template if validation fails" do
      post :create, default_params
      expect(response).to be_success
      expect(response).to render_template(:new)
    end

    it "returns http success and redirects to index if validation is valid" do
      mock_secret = double('mock_secret').as_null_object
      allow_any_instance_of(ServiceLayer::KeyManagerService).to receive(:new_secret).and_return(mock_secret)
      allow(mock_secret).to receive(:save).and_return(true)
      allow(mock_secret).to receive(:valid?).and_return(true)

      post :create, default_params.merge({secret: ::KeyManager::FakeFactory.new.secret.attributes})
      expect(response).to redirect_to(secrets_path(default_params))
    end

  end

end