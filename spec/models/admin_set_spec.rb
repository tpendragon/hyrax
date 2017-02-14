require 'spec_helper'

RSpec.describe AdminSet, type: :model do
  let(:gf1) { create(:generic_work, user: user) }
  let(:gf2) { create(:generic_work, user: user) }
  let(:gf3) { create(:generic_work, user: user) }

  let(:user) { create(:user) }

  before do
    subject.title = ['Some title']
  end

  describe '#permission_template' do
    it 'queries for a Hyrax::PermissionTemplate with a matching admin_set_id' do
      admin_set = build(:admin_set, id: '123')
      permission_template = build(:permission_template)
      expect(Hyrax::PermissionTemplate).to receive(:find_by!).with(admin_set_id: '123').and_return(permission_template)
      expect(admin_set.permission_template).to eq(permission_template)
    end
  end

  describe "#to_solr" do
    let(:admin_set) do
      build(:admin_set, title: ['A good title'],
                        creator: ['jcoyne@justincoyne.com'])
    end
    let(:solr_document) { admin_set.to_solr }

    it "has title and creator information" do
      expect(solr_document).to include 'title_tesim' => ['A good title'],
                                       'title_sim' => ['A good title'],
                                       'creator_ssim' => ['jcoyne@justincoyne.com']
    end
  end

  describe "#members" do
    it "is empty by default" do
      expect(subject.members).to be_empty
    end

    context "adding members" do
      context "using assignment" do
        subject { described_class.create!(title: ['Some title'], members: [gf1, gf2]) }

        it "has many files" do
          expect(subject.reload.members).to match_array [gf1, gf2]
        end
      end

      context "using append" do
        before do
          subject.members = [gf1]
          subject.save
        end
        it "allows new files to be added" do
          subject.reload
          subject.members << gf2
          subject.save
          expect(subject.reload.members).to match_array [gf1, gf2]
        end
      end
    end
  end

  it "has a title" do
    subject.title = ["title"]
    subject.save
    expect(subject.reload.title).to eq ["title"]
  end

  it "has a description" do
    subject.title = ["title"]
    subject.description = ["description"]
    subject.save
    expect(subject.reload.description).to eq ["description"]
  end

  describe "#default_set?" do
    context "with default AdminSet" do
      before do
        subject.id = described_class::DEFAULT_ID
        subject.save!
      end
      it "returns true" do
        expect(subject.default_set?).to be true
      end
    end

    context "with randomly assigned ID" do
      it "returns false" do
        expect(subject.default_set?).to be false
      end
    end
  end

  describe "#destroy" do
    context "with member works" do
      before do
        subject.members = [gf1, gf2]
        subject.save!
        subject.destroy
      end

      it "does not delete adminset or member works" do
        expect(subject.errors.full_messages).to eq ["Administrative set cannot be deleted as it is not empty"]
        expect(AdminSet.exists?(subject.id)).to be true
        expect(GenericWork.exists?(gf1.id)).to be true
        expect(GenericWork.exists?(gf2.id)).to be true
      end
    end

    context "with no member works" do
      before do
        subject.members = []
        subject.save!
        subject.destroy
      end

      it "deletes the adminset" do
        expect(AdminSet.exists?(subject.id)).to be false
      end
    end

    context "is default adminset" do
      before do
        subject.members = []
        subject.id = described_class::DEFAULT_ID
        subject.save!
        subject.destroy
      end

      it "does not delete the adminset" do
        expect(subject.errors.full_messages).to eq ["Administrative set cannot be deleted as it is the default set"]
        expect(AdminSet.exists?(described_class::DEFAULT_ID)).to be true
      end
    end
  end
end
