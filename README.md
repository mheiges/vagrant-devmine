# devmine

This is a Vagrant project to host a development copy of EuPathDB's
Redmine 2.x/CentOS 6.

It is primarily focused on being a playground for migrating to new
versions, such as EasyRedmine.

Once provisioned, Redmine should be available at http://devmine.vm.apidb.org/

## Common task options

#### Copy our production Redmine 2.x

To make a reproduction of our production Redmine 2.x, add
`scratch/redmine_dump.sql.gz` to the local project dir.

In `playbook.yml` set vars
    do_redmine_db_import: True
    do_redmine_plugin_unmigrate: False
    redmine_db_dump_file: <NAME OF redmine_dump.sql.gz>

#### Copy and un-migrate our production Redmine 2.x

To make a reproduction of our production Redmine 2.x and then remove all
plugins to prepare the database for a different version of Redmine
(e.g. EasyRedmine).

Add `scratch/redmine_dump.sql.gz` to the local project dir.

In `playbook.yml` set vars
    do_redmine_db_import: True
    do_redmine_plugin_unmigrate: True
    do_dump_unmigrated_redmine_db: True
    do_dump_unmigrated_redmine_db: True
    redmine_db_dump_file: <NAME OF redmine_dump.sql.gz>
    redmine_db_unmigrated_dump_outfile: '{{ cache_dir }}/redmine_unmigrated_dump.sql.gz'

If `do_dump_unmigrated_redmine_db` is `True`, the cleaned database will
be dumped to `redmine_db_unmigrated_dump_outfile`. This file can then be
used for the other Redmine version you want to port to - for example, our
EasyRedmine Vagrant project (https://github.com/mheiges/vagrant-easyredmine).

##### Re-import database

Once Ansible imports the `redmine_db_dump_file` it will skip the step on
subsequent provisioning. To force it to import again either remove
the `/tmp/redmine_db_import_success` file or drop the
`redmine_db_name` database on the remote.

## Requirements

- `scratch/redmine_dump.sql.gz` - a mysql dump of our production
database.  _(One of the daily backups on our production Redmine server
is suitable. See `/var/lib/mysql.backups/daily/redmine/`.)_

- `scratch/redmine-2.3.2.tar.gz` - an archive of
`/usr/local/redmine-2.3.2` from our production Redmine installation.

- Vagrant `landrush` plugin

- A VPN tunnel to UGA's campus so LDAP authentication queries can complete.

## Provisioning

Start the virtual machine with `vagrant up`.

The VM is provisioned with Ansible. The following steps are performed.

- install software packages, including EuPathDB's redmine bundle.
- install Nginx and configure a virtual host.
- install mysql, create a database, import
`scratch/redmine_dump.sql.gz`. The import can be skipped by setting
`do_redmine_db_import` to `False` in the playbook vars.
- Replace the redmine directory that was installed by the `redmine`
rpm with the contents of `scratch/redmine-2.3.2.tar.gz`
- passwords used in production will be changed

## Uninstalling plugins

One of the intents of this virtual machine is to try out different
migration scenarios. Some scenarios require removing plugins. Here are
the basic steps.

    # cd /usr/local/redmine-2.3.2
    # source setenv

    # rake redmine:plugins:migrate NAME=projects_tree_view VERSION=0 RAILS_ENV=production 
    # rake redmine:plugins:migrate NAME=redmine_eupathdb_average_priorities VERSION=0 RAILS_ENV=production 
    # rake redmine:plugins:migrate NAME=redmine_extra_query_operators VERSION=0 RAILS_ENV=production


    # rake redmine:plugins:migrate NAME=redmine_issue_checklist VERSION=0 RAILS_ENV=production 
    Migrating redmine_issue_checklist (Redmine Issue Checklist plugin)...
    ==  CreateIssueChecklists: reverting ==========================================
    -- drop_table(:issue_checklists)
       -> 0.0803s
    ==  CreateIssueChecklists: reverted (0.0804s) =================================


    # rake redmine:plugins:migrate NAME=redmine_plugin_views_revisions VERSION=0 RAILS_ENV=production 


    # mv plugins plugins_
    # mkdir plugins
    # service nginx restart


## Dump database

To dump the database so you can imported on another VM, e.g.
`vagrant-easyredmine`, do

    mysqldump -u root --databases redmine > /vagrant/deplugged-redmine.sql