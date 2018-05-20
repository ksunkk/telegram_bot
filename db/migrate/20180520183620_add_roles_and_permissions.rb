class AddRolesAndPermissions < ActiveRecord::Migration[5.2]
  def change
    roles = YAML.load_file('config/roles.yml')
    permissions = YAML.load_file('config/permissions.rb').map(&:with_indifferent_access)
    roles.each { |role_params| Role.create(role_params) }
    permissions.each do |permission_params|
      Permission.create(permission_params.fetch(:id, :action_name, :name))
      permission_params[:available_for].each do |role|
        execute <<-SQL
          INSERT INTO roles_permissions 
          SELECT #{permission_params[:id]}, id
          FROM telegram_roles
          WHERE code = #{role}
        SQL
      end
    end
  end
end
