module AutoWatch
	module IssuePatch
		def self.included(base)
			base.class_eval do
				unloadable

				def autowatch_add_watcher(watcher)
					return if watcher.nil? || !watcher.is_a?(User) || watcher.anonymous? || !watcher.active?
					self.add_watcher(watcher) unless self.watched_by?(watcher)
				end

				def autowatch_hook
					autowatch_add_watcher(self.author)
					autowatch_add_watcher(self.assigned_to)
				end

				def autowatch_aroundsave_hook
					autowatch_hook
					yield
					autowatch_hook
				end

				around_save :autowatch_aroundsave_hook
			end
		end
	end
end

Issue.send(:include, AutoWatch::IssuePatch)

