require_relative "base_service"

module Files
  class UpdateService < BaseService
    def execute
      allowed = ::Gitlab::GitAccess.can_push_to_branch?(current_user, project, ref)

      unless allowed
        return error("You are not allowed to push into this branch")
      end

      unless repository.branch_names.include?(ref)
        return error("You can only create files if you are on top of a branch")
      end

      blob = repository.blob_at_branch(ref, path)

      unless blob
        return error("You can only edit text files")
      end

      edit_file_action = Gitlab::Satellite::EditFileAction.new(current_user, project, ref, path)
      created_successfully = edit_file_action.commit!(
        params[:content],
        params[:commit_message],
        params[:encoding]
      )

      if created_successfully
        success
      else
        error("Your changes could not be committed. Maybe the file was changed by another process or there was nothing to commit?")
      end
    end
  end
end
