module AutoWatch
	module IssuePatch
		def self.included(base)
			base.class_eval do
				unloadable

				def autowatch_add_watcher(watcher)
					return if watcher.nil? || !watcher.is_a?(User) || watcher.anonymous? || !watcher.active?
					self.add_watcher(watcher) unless self.watched_by?(watcher)
				end

				def autowatch_beforesave_hook
					Rails.logger.info(self.to_yaml)
					autowatch_add_watcher(self.author)
					autowatch_add_watcher(self.assigned_to)
				end

				around_save :autowatch_beforesave_hook
			end
		end
	end
end

Issue.send(:include, AutoWatch::IssuePatch)

