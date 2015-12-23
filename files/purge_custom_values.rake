desc <<-END_DESC
Delete orphaned custom_values table rows from the database that once belonged to Projects that are now deleted. This
cleanup is needed before migrating to Easy Redmine.

Example:
  rake redmine:purge_custom_values RAILS_ENV=production 
END_DESC
namespace :redmine do
  task :purge_custom_values => :environment do
    CustomValue.where(:customized_type => 'Project').
    preload(:customized).
    find_each(:batch_size => 100) do |x|
      x.delete if x.customized.nil?
    end
  end
end