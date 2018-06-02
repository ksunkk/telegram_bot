class AddRoles < ActiveRecord::Migration[5.2]
  def change
    roles = YAML.load_file('config/roles.yml')
    roles.each { |role_params| Role.create(role_params) unless Role.where(id: role_params['id']).present? }
  end
end
