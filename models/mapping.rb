class Mapping < ApplicationRecord

  after_update :delete_clone_mapping, if: :deleted?
  after_update :update_clone_mapping, if: :list_attribute_changed?

  audited

  def count_item
    list.split("\n").count
  end

  private

  def deleted?
    !self.status
  end

  def list_attribute_changed?
    self.saved_change_to_list?
  end

  def delete_clone_mapping

    insurers = Insurer.where(status: true).where.not(mapping: nil)
    insurers.each do |insurer|
      next if insurer.mapping.blank?
      mapping_array = JSON.parse(insurer.mapping)
      next if mapping_array.blank?
      next unless mapping_array.any? {|s| s['id'] == self.id.to_s}
      index = mapping_array.index {|s| s['id'] == self.id.to_s }
      mapping_array.delete_at(index.to_i)

      # update insurer clone mapping
      insurer.update(mapping: mapping_array.to_json)

      apis = insurer.insurer_product_apis.where(status: true).where.not(payload_validation: nil)
      apis.each do |api|
        pv = JSON.parse(api.payload_validation)
        next if pv.blank?
        next unless pv.any? {|s| s['mapping'] == self.id.to_s}
        pv.each_with_index do |validation, index|
          next if validation['mapping'].blank?
          next unless validation['mapping'] == self.id.to_s
          # update mapping value at payload validation
          pv[index]['mapping'] = ''
        end

        # update insurer product api
        api.update(payload_validation: pv.to_json)
      end

    end
  end

  def update_clone_mapping
    # current mapping: {Doctor Nurse}
    # add new values (list) {Doctor Nurse Cleaner}
    # edit values (list) {Doc Nur Cleaner}
    # remove values (list) {Nurse Cleaner}
    list_array = list.split
    mapping_id = id
    insurers = Insurer.where(status: true).where.not(mapping: nil)
    insurers.each do |insurer|
      new_master_array = []
      new_value_array = []

      next if insurer.mapping.blank?
      mapping_array = JSON.parse(insurer.mapping)
      next if mapping_array.blank?
      next unless mapping_array.any? {|s| s['id'] == mapping_id.to_s}
      index = mapping_array.index {|s| s['id'] == mapping_id.to_s }

      # get current mapping master and value
      previous_master_array = mapping_array[index]['master']
      previous_value_array = mapping_array[index]['value']

      # Set new value
      new_master_array = list_array
      new_master_array.each_with_index do |master, index|
        new_value_array << previous_value_array[index]
      end

      #update mapping array
      new_mapping_array = mapping_array
      new_mapping_array[index]['master'] = new_master_array
      new_mapping_array[index]['value'] = new_value_array

      insurer.update(mapping: new_mapping_array.to_json)
      puts "json: #{new_mapping_array.to_json}"
    end
  end

end
