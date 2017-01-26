# Converts UploadedFiles into FileSets and attaches them to works.
class AttachFilesToWorkJob < ActiveJob::Base
  queue_as Hyrax.config.ingest_queue_name

  before_enqueue do |job|
    log = job.arguments.last
    log.pending_job(self)
  end

  # @param [ActiveFedora::Base] the work class
  # @param [Array<UploadedFile>] an array of files to attach
  # @param [Hyrax::Operation] a log storing the status of the job
  def perform(work, uploaded_files, log)
    log.performing!
    uploaded_files.each do |uploaded_file|
      file_set = FileSet.new
      user = User.find_by_user_key(work.depositor)
      actor = Hyrax::Actors::FileSetActor.new(file_set, user)
      actor.create_metadata(visibility: work.visibility)
      attach_content!(actor, uploaded_file.file, log)
      actor.attach_file_to_work(work)
      actor.file_set.permissions_attributes = work.permissions.map(&:to_hash)

      uploaded_file.update(file_set_uri: file_set.uri)
    end
    # TODO: Should this depend on whether child_log was a success?
    log.success!
  end

  private

    # @param [Hyrax::Actors::FileSetActor] actor
    # @param [UploadedFileUploader] file
    # @param [Hyrax::Operation] a log storing the status of the job
    def attach_content!(actor, file, log)
      child_log = Hyrax::Operation.create!(user: actor.user,
                                           operation_type: 'Attach File',
                                           parent: log)
      child_log.performing!
      case file.file
      when CarrierWave::SanitizedFile
        actor.create_content(file.file.to_file)
        child_log.success!
      when CarrierWave::Storage::Fog::File
        import_url!(actor, file, child_log)
        child_log.success!
      else
        error_message = "Unknown type of file #{file.class}"
        child_log.fail!(error_message)
        raise ArgumentError, error_message
      end
    end

    # @param [Hyrax::Actors::FileSetActor] actor
    # @param [UploadedFileUploader] file
    # @param [Hyrax::Operation] a log storing the status of the job
    def import_url!(actor, file, log)
      actor.file_set.update(import_url: file.url)
      ImportUrlJob.perform_later(actor.file_set, log)
    end
end
