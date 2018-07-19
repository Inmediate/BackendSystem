class InsurerMappingController < InsurerController

  def new
    @insurer = Insurer.find(params[:insurer_id])
    @insurer_mapping_id_array = []
    unless @insurer.mapping.blank?
      JSON.parse(@insurer.mapping).each do |map|
        @insurer_mapping_id_array << map['id'].to_i
      end
    end

    add_breadcrumb @insurer.company_name, "/insurer/edit/#{@insurer.id}"
    add_breadcrumb "Clone A Mapping"
    add_breadcrumb "New"
  end

  def create
    insurer = Insurer.find(params[:insurer_id])
    # hash example = [{"id" => 1, "master" => [male, female], "value" => [boy, girl]},{"id" => 2, "master" => [Police, Doctor], "value" => [Polis, Doktor]}]

    mapping_hash = {}
    mapping_hash['id'] = params[:mapping]
    mapping_hash['master'] = []
    Mapping.find(params[:mapping]).list.split("\n").each { |s| mapping_hash['master'] << s.gsub(/\s+/, '')}
    puts "mapping_hash['master']: #{ mapping_hash['master']}"
    mapping_hash['value'] = []

    if insurer.mapping.blank?
      mapping_array = []
    else
      mapping_array = JSON.parse(insurer.mapping)
    end
    mapping_array << mapping_hash

    # chech for existing approval
    approval = Approval.where(table:'INSURER').where(row_id: insurer.id)
    if approval.any?
      content_hash = JSON.parse(approval.first.content)
      content_hash['mapping'] = mapping_array.to_json
      approval.first.update(content:  content_hash.to_json, user: current_user.id)
    else

      content_hash = insurer.attributes.except('id', 'status', 'created_at', 'updated_at')
      content_hash['mapping'] = mapping_array.to_json
      content_hash[:activation_status] = insurer.activation_status.to_s

      # get products
      products = []
      insurer.products.each do |product|
        products << product.id
      end

      content_hash[:products] = products.to_json

      Approval.create(
          table: 'INSURER',
          row_id: insurer.id,
          content: content_hash.to_json,
          user: current_user.id
      )
    end

    flash[:success] = "Add new Clone Mapping to Insurer"
    redirect_to "/insurer/#{insurer.id}/mapping/edit/#{params[:mapping]}"

  end

  def edit
    @insurer = Insurer.find(params[:insurer_id])
    @mapping_hash = {}

    approval = Approval.where(table:'INSURER').where(row_id: @insurer.id)
    if approval.any?
      hash_content = JSON.parse(approval.first.content)
      mapping_array_pending = JSON.parse(hash_content['mapping'])
      mapping_array_pending.each do |map|
        if map['id'].to_i == params[:id].to_i
          @mapping_hash = map
          break
        end
      end
    else
      JSON.parse(@insurer.mapping).each do |map|
        if map['id'].to_i == params[:id].to_i
          @mapping_hash = map
          break
        end
      end
    end


    if @mapping_hash.blank?
      flash[:error] = "Somethings wrong when adding Clone Mapping, Please try again."
      redirect_to "/insurer/#{@insurer.id}/mapping/new"
      return
    end


    @mapping = []
    Mapping.find(params[:id]).list.split("\n").each { |s| @mapping << s.gsub(/\s+/, '')}
    # @mapping = Mapping.find(params[:id]).list.gsub(/\s+/, '').split("\n")
    @mapping_name = Mapping.find(params[:id]).name
    @id = params[:id]

    add_breadcrumb @insurer.company_name, "/insurer/edit/#{@insurer.id}"
    add_breadcrumb "Clone A Mapping"
    add_breadcrumb "Edit"
  end

  def update
    # insurer = Insurer.find(params[:insurer_id])
    # mapping_array = []
    # mapping_index = nil
    # JSON.parse(insurer.mapping).each_with_index do |map, index|
    #   if map.first == params[:id]
    #     mapping_array = map
    #     mapping_index = index
    #     break
    #   end
    # end

    # if mapping_array.blank?
    #   flash[:error] = "Somethings wrong when editing Clone Mapping, Please try again."
    #   redirect_to "/insurer/#{insurer.id}/mapping/edit/#{params[:id]}"
    #   return
    # end

    # update mapping
    # mapping_head = JSON.parse(insurer.mapping)
    # mapping_head.delete_at(mapping_index)
    # mapping_id = [params[:id]]
    # mapping_master_arr = []
    # mapping_value_arr = []
    #
    # unless params[:mapping]['master'].blank?
    #   params[:mapping]['master'].each do |master|
    #     mapping_master_arr << master
    #   end
    # end
    #
    # unless params[:mapping]['value'].blank?
    #   params[:mapping]['value'].each do |value|
    #     mapping_value_arr << value
    #   end
    # end
    #
    # # update map list
    # mapping_id << mapping_master_arr << mapping_value_arr
    # mapping_head << mapping_id
    # insurer.update(mapping: mapping_head.to_json)
    #

    insurer = Insurer.find(params[:insurer_id])
    mapping_id = params[:id]
    # hash example = [{"id" => 1, "master" => [male, female], "value" => [boy, girl]},{"id" => 2, "master" => [Police, Doctor], "value" => [Polis, Doktor]}]

    # if insurer.mapping.blank?
    #     flash[:error] = "Somethings wrong when editing Clone Mapping, Please try again."
    #     redirect_to "/insurer/#{insurer.id}/mapping/edit/#{params[:id]}"
    #     return
    # end

    # chech for existing approval
    approval = Approval.where(table:'INSURER').where(row_id: insurer.id)
    mapping_hash = {}
    if approval.any?
      content_hash = JSON.parse(approval.first.content)
      mapping_array = []
      JSON.parse(content_hash['mapping']).each do |map|
        if map['id'] == mapping_id
          map['value'] = params[:mapping]['value'].blank? ? [] : params[:mapping]['value']
          mapping_array << map
        else
          mapping_array << map
        end
      end

      content_hash[:mapping] = mapping_array.to_json
      approval.first.update(content:  content_hash.to_json, user: current_user.id)
    else

      content_hash = insurer.attributes.except('id', 'status', 'created_at', 'updated_at')
      mapping_array = []
      JSON.parse(content_hash['mapping']).each do |map|
        if map['id'] == mapping_id
          map['value'] = params[:mapping]['value'].blank? ? [] : params[:mapping]['value']
          mapping_array << map
        else
          mapping_array << map
        end
      end

      # get products
      products = []
      insurer.products.each do |product|
        products << product.id
      end

      content_hash[:products] = products.to_json
      content_hash[:mapping] = mapping_array.to_json
      content_hash[:activation_status] = insurer.activation_status.to_s

      Approval.create(
          table: 'INSURER',
          row_id: insurer.id,
          content: content_hash.to_json,
          user: current_user.id
      )
    end

    flash[:success] = "Success edit Clone Mapping to Insurer"
    redirect_to "/insurer/edit/#{insurer.id}"
  end

  def delete

    insurer = Insurer.find(params[:insurer_id])
    mapping_id = params[:id]


    # mapping_array = []
    # mapping_index = nil
    # JSON.parse(insurer.mapping).each_with_index do |map, index|
    #   if map.first == params[:id]
    #     mapping_array = map
    #     mapping_index = index
    #     break
    #   end
    # end
    #
    # mapping_head = JSON.parse(insurer.mapping)
    # mapping_head.delete_at(mapping_index)
    # insurer.update(mapping: mapping_head.to_json)



    approval = Approval.where(table:'INSURER').where(row_id: insurer.id)
    mapping_hash = {}
    if approval.any?
      content_hash = JSON.parse(approval.first.content)
      mapping_array = []
      JSON.parse(content_hash['mapping']).each do |map|
        unless map['id'] == mapping_id
          mapping_array << map
        end
      end

      content_hash[:mapping] = mapping_array.to_json
      approval.first.update(content:  content_hash.to_json, user: current_user.id)
    else

      content_hash = insurer.attributes.except('id', 'status', 'created_at', 'updated_at')
      mapping_array = []
      JSON.parse(content_hash['mapping']).each do |map|
        unless map['id'] == mapping_id
          mapping_array << map
        end
      end

      # get products
      products = []
      insurer.products.each do |product|
        products << product.id
      end

      content_hash[:products] = products.to_json
      content_hash[:mapping] = mapping_array.to_json
      content_hash[:activation_status] = insurer.activation_status.to_s

      Approval.create(
          table: 'INSURER',
          row_id: insurer.id,
          content: content_hash.to_json,
          user: current_user.id
      )
    end


    flash[:success] = "Pending delete Clone Mapping to Insurer"
    redirect_to "/insurer/edit/#{insurer.id}"
  end

end
