require 'spec_helper'

RSpec.describe Hyrax::WorkflowActionsController, type: :controller do
  let(:user) { FactoryGirl.create(:user) }
  let(:generic_work) { GenericWork.new(id: '123') }
  let(:form) { instance_double(Hyrax::Forms::WorkflowActionForm) }
  routes { Rails.application.routes }

  before do
    allow(ActiveFedora::Base).to receive(:find).with(generic_work.to_param).and_return(generic_work)
    allow(generic_work).to receive(:persisted?).and_return(true)
    allow(Hyrax::Forms::WorkflowActionForm).to receive(:new).and_return(form)
  end

  describe '#update' do
    it 'will redirect to login path if user not authenticated' do
      put :update, params: { id: generic_work.to_param, workflow_action: { name: 'advance', comment: '' } }
      expect(response).to redirect_to(main_app.user_session_path)
    end

    it 'will render :unauthorized when action is not valid for the given user' do
      expect(form).to receive(:save).and_return(false)
      sign_in(user)

      put :update, params: { id: generic_work.to_param, workflow_action: { name: 'advance', comment: '' } }
      expect(response).to be_unauthorized
    end

    it 'will redirect when the form is successfully save' do
      expect(form).to receive(:save).and_return(true)
      sign_in(user)

      put :update, params: { id: generic_work.to_param, workflow_action: { name: 'advance', comment: '' } }
      expect(response).to redirect_to(main_app.hyrax_generic_work_path(generic_work, locale: 'en'))
    end
  end
end
