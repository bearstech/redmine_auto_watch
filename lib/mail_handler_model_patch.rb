module AutoWatch
	module MailHandlerPatch
		def self.included(base)
			base.send(:include, InstanceMethods)

			base.class_eval do
				unloadable

				def receive_issue_with_auto_watch
					# The code of this function is a copy of https://github.com/redmine/redmine/blob/master/app/models/mail_handler.rb#L187

					project = target_project
					# check permission
					unless @@handler_options[:no_permission_check]
						raise UnauthorizedAction unless user.allowed_to?(:add_issues, project)
					end

					issue = Issue.new(:author => user, :project => project)

					issue.safe_attributes = issue_attributes_from_keywords(issue)
					issue.safe_attributes = {'custom_field_values' => custom_field_values_from_keywords(issue)}
					issue.subject = cleaned_up_subject
					if issue.subject.blank?
						issue.subject = '(no subject)'
					end
					issue.description = cleaned_up_text_body
					issue.start_date ||= Date.today if Setting.default_issue_start_date_to_creation_date?

					# add To and Cc as watchers before saving so the watchers can reply to Redmine
					issue.add_watcher(issue.author)
					issue.add_watcher(issue.assigned_to)
					add_watchers(issue)
					issue.save!
					add_attachments(issue)
					logger.info "MailHandler: issue ##{issue.id} created by #{user}" if logger
					issue
				end
				alias_method_chain :receive_issue, :auto_watch
			end
		end

		module InstanceMethods
		end
	end
end

MailHandler.send(:include, AutoWatch::MailHandlerPatch)

