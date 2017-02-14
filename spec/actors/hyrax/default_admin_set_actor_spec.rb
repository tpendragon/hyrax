require 'spec_helper'

RSpec.describe Hyrax::DefaultAdminSetActor do
  let(:next_actor) do
    double('next actor', create: true,
                         curation_concern: work,
                         update: true,
                         user: depositor)
  end
  let(:actor) do
    Hyrax::Actors::ActorStack.new(work, depositor, [described_class])
  end
  let(:depositor) { create(:user) }
  let(:work) { build(:generic_work) }
  let(:admin_set) { create(:admin_set) }
  let(:permission_template) { create(:permission_template, admin_set_id: admin_set.id) }

  describe "create" do
    before do
      allow(Hyrax::Actors::RootActor).to receive(:new).and_return(next_actor)
    end

    context "when admin_set_id is blank" do
      let(:attributes) { { admin_set_id: '' } }
      let(:default_id) { AdminSet::DEFAULT_ID }

      it "creates the default AdminSet with a PermissionTemplate and calls the next actor with the default admin set id" do
        expect(next_actor).to receive(:create).with(admin_set_id: default_id).and_return(true)
        expect { actor.create(attributes) }.to change { AdminSet.count }.by(1)
          .and change { Hyrax::PermissionTemplate.count }.by(1)
      end
    end

    context "when admin_set_id is provided" do
      let(:attributes) { { admin_set_id: admin_set.id } }

      it "uses the provided id and returns true" do
        expect(next_actor).to receive(:create).with(attributes).and_return(true)
        expect(actor.create(attributes)).to be true
      end
    end
  end

  describe "#create_default_admin_set" do
    let(:actor) { described_class.new(double, double, double) }
    context "when another thread has already created the admin set" do
      before do
        AdminSet.create!(id: AdminSet::DEFAULT_ID, title: ['Default Admin Set'])
      end
      it "doesn't raise an error" do
        expect { actor.send(:create_default_admin_set) }.not_to raise_error
      end
    end
  end
end
