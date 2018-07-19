#= require ./application

$(document).ready ->
  $('#add_header').click ->
    position_header = $('#row_header tr').length
    $("#row_header > tbody ").append('
        <tr id="payload_row">
          <td>'+position_header+'</td>
          <td><input type="text" name="insurer_product_api[headers][][head]" class="form-control"></td>
          <td><input type="text" name="insurer_product_api[headers][][value]" class="form-control"></td>
          <td><button type="button" class="btn btn-danger" id="remove_header">remove</button></td>
        </tr>
      ');

  $('#row_header').on 'click', '#remove_header', ->
    $(this).closest('tr').remove()
    return

  $('#add_payload_validation').click ->
#    get input value
    name = $('#new_name').val()
    ref_name = $('#new_name_reference').val()
    validation = $('#new_validation').val()
    mapping = $('#new_mapping :selected').text()
    mapping_id = $('#new_mapping :selected').val()
    if mapping_id == undefined
      mapping_id = ''
    mandatory = false
    enable_validation = false
    is_array = false
    encrypted = false
    parent_array = $('#new_parent_array').val()
    description = $('#new_description').val()

    mandatory_color = "style=\"color: #5cb85c\""
    enable_validation_color = 'style="color: #5cb85c"'
    is_array_color = 'style="color: #5cb85c"'
    encrypted_color = 'style="color: #5cb85c"'

    if $('#new_mandatory').is(':checked')
      mandatory = true
    else
      mandatory_color = "style=\"color: #d9534f\""

    if $('#new_enable_validation').is(':checked')
      enable_validation = true
    else
      enable_validation_color = 'style="color: #d9534f"'

    if $('#new_is_array').is(':checked')
      is_array = true
    else
      is_array_color = 'style="color: #d9534f"'

    if $('#new_encrypted').is(':checked')
      encrypted = true
    else
      encrypted_color = 'style="color: #d9534f"'

    # create table value
    position = $('#row_payload_validation tr').length
    $("#row_payload_validation > tbody ").append('
        <tr id="'+position+'">
          <td>'+position+'</td>
          <td id="row_payload_name_'+position+'">'+name+'</td>
          <input type="hidden" name="insurer_product_api[payload_validation][][name]" id="payload_name_'+position+'" value="'+name+'">
          <td id="row_payload_ref_name_'+position+'" >'+ref_name+'</td>
          <input type="hidden"  name="insurer_product_api[payload_validation][][ref_name]" id="payload_ref_name_'+position+'" value="'+ref_name+'">
          <td style="white-space: pre-wrap;" id="row_payload_validation_'+position+'" >'+validation+'</td>
          <input type="hidden" name="insurer_product_api[payload_validation][][validation]" id="payload_validation_'+position+'" value="'+validation+'">
          <td id="row_payload_mapping_'+position+'" >'+mapping+'</td>
          <input type="hidden" name="insurer_product_api[payload_validation][][mapping]"  id="payload_mapping_id_'+position+'" value="'+mapping_id+'" >
          <td id="row_payload_mandatory_'+position+'"  '+mandatory_color+' >'+mandatory+'</td>
          <input type="hidden" name="insurer_product_api[payload_validation][][mandatory]"  id="payload_mandatory_'+position+'" value="'+mandatory+'" >
          <td id="row_payload_enable_validation_'+position+'"  '+enable_validation_color+' >'+enable_validation+'</td>
          <input type="hidden" name="insurer_product_api[payload_validation][][enable_validation]"  id="payload_enable_validation_'+position+'" value="'+enable_validation+'" >
          <td id="row_payload_encrypted_'+position+'" '+encrypted_color+' >'+encrypted+'</td>
          <input type="hidden" name="insurer_product_api[payload_validation][][encrypted]"  id="payload_encrypted_'+position+'" value="'+encrypted+'" >
          <td id="row_payload_is_array_'+position+'" '+is_array_color+' >'+is_array+'</td>
          <input type="hidden" name="insurer_product_api[payload_validation][][is_array]"  id="payload_is_array_'+position+'" value="'+is_array+'" >
          <td id="row_payload_parent_array_'+position+'" >'+parent_array+'</td>
          <input type="hidden" name="insurer_product_api[payload_validation][][parent_array]"  id="payload_parent_array_'+position+'" value="'+parent_array+'" >
          <td id="row_payload_description_'+position+'" >'+description+'</td>
          <input type="hidden" name="insurer_product_api[payload_validation][][description]"  id="payload_description_'+position+'" value="'+description+'" >
          <td><a href="#" id="edit_payload_validation" data-toggle="modal" data-target="#'+position+'_modal" ><span class="glyphicon glyphicon-edit" aria-hidden="true"></span></a></td>
        </tr>
      ');

    # remove reset modal form
    $('#new_name').val('')
    $('#new_name_reference').val('')
    $('#new_validation').val('')
    $('#new_mapping :selected').removeAttr('selected');
    $('#new_mandatory').removeAttr('checked');
    $('#new_enable_validation').removeAttr('checked');
    $('#new_is_array').removeAttr('checked');
    $('#new_encrypted').removeAttr('checked');
    $('#new_parent_array').val('')
    $('#new_description').val('')

    insurer_mapping_name_array = JSON.parse($('#insurer_mapping_name_array').val())
    insurer_mapping_id_array = JSON.parse($('#insurer_mapping_id_array').val())
    option_select = ''
    $.each insurer_mapping_name_array, (index, value) ->
      option_select += '<option value="'+insurer_mapping_id_array[index]+'">' +value+ '</option>'
      return

    $("#modal_creation").append('
      <div class="modal fade" id="'+position+'_modal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel">
        <div class="modal-dialog modal-lg" role="document">
          <div class="modal-content">
            <div class="modal-header">
              <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
              <h4 class="modal-title" id="myModalLabel">Add Payload Validation</h4>
            </div>
            <div class="modal-body">

              <div class="form-group">
                <label>Variable Name:<span>&#42;</span></label>
                <input type="text" class="form-control" value="" id="form_payload_name_'+position+'">
              </div>

              <div class="form-group">
                <label>Key Name Reference:</label>
                <input type="text" class="form-control" value="" id="form_payload_ref_name_'+position+'">
              </div>

              <div class="form-group">
                <label>Validation:</label>
                <p><em>Enter validations separated with new lines.</em></p>
                <textarea name="" class="form-control" id="form_payload_validation_'+position+'" cols="30" rows="3"></textarea>
              </div>

              <div class="form-group">
                <label>Mapping List:</label>
                <select id="form_payload_mapping_'+position+'" class="form-control">
                  <option value=""></option>' +option_select+ '</select>

                </select>
              </div>

              <div class="form-group">
                <label>Mandatory?:</label><br>
                <input type="checkbox" value="true" id="form_payload_mandatory_'+position+'" >
                Check if yes
              </div>

              <div class="form-group">
                <label>Enable Validation?:</label><br>
                <input type="checkbox" value="true" id="form_payload_enable_validation_'+position+'" >
                Check if yes
              </div>

               <div class="form-group">
                <label>Encrypted?:</label><br>
                <input type="checkbox" value="true"  id="form_payload_encrypted_'+position+'" >
                Check if yes
              </div>


              <div class="form-group">
                <label>Is Array?:</label><br>
                <input type="checkbox" value="true"  id="form_payload_is_array_'+position+'" >
                Check if yes
              </div>

              <div class="form-group">
                <label>Belongs to Array Block:</label>
                <input type="text" class="form-control" value=""  id="form_payload_parent_array_'+position+'">
              </div>

              <div class="form-group">
                <label>Description:</label>
                <input type="text" class="form-control" value=""  id="form_payload_description_'+position+'" >
              </div>

            </div>
            <div class="modal-footer">
              <button type="button" class="btn btn-danger delete_payload_validation" id="'+position+'" data-dismiss="modal">Remove</button>
              <button type="button" class="btn btn-primary update_payload_validation" id="'+position+'" data-dismiss="modal" >Confirm</button>
            </div>
          </div>
        </div>
      </div>
      ');

  $('#row_payload_validation').on 'click', '#edit_payload_validation', ->
    index = $(this).closest('tr').index()
    position = index + 1

    # get value from table
    name = $('#payload_name_'+position).val()
    ref_name = $('#payload_ref_name_'+position).val()
    validation = $('#payload_validation_'+position).val()
    mapping_id = $('#payload_mapping_id_'+position).val()
    parent_array = $('#payload_parent_array_'+position).val()
    description = $('#payload_description_'+position).val()

    # update value to form
    $('#form_payload_name_'+position).val(name)
    $('#form_payload_ref_name_'+position).val(ref_name)
    $('#form_payload_mapping_'+position).val(mapping_id)
    $('#form_payload_validation_'+position).val(validation)
    $('#form_payload_parent_array_'+position).val(parent_array)
    $('#form_payload_description_'+position).val(description)

    if $('#payload_mandatory_'+position).val() == 'true'
      $('#form_payload_mandatory_'+position).attr('checked','checked')

    if $('#payload_enable_validation_'+position).val() == 'true'
      $('#form_payload_enable_validation_'+position).attr('checked','checked')

    if $('#payload_is_array_'+position).val() == 'true'
      $('#form_payload_is_array_'+position).attr('checked','checked')

    if $('#payload_encrypted_'+position).val() == 'true'
      $('#form_payload_encrypted_'+position).attr('checked','checked')

  $(document).on 'click', '.update_payload_validation', (event) ->
    position = $(this).attr('id')

    # get form value
    name = $('#form_payload_name_'+position).val()
    ref_name = $('#form_payload_ref_name_'+position).val()
    validation = $('#form_payload_validation_'+position).val()
    mapping = $('#form_payload_mapping_'+position+' :selected').text()
    mapping_id = $('#form_payload_mapping_'+position).val()
    mandatory = false
    enable_validation = false
    encrypted = false
    is_array = false
    parent_array = $('#form_payload_parent_array_'+position).val()
    description = $('#form_payload_description_'+position).val()
    if $('#form_payload_mandatory_'+position).is(':checked')
      mandatory = true

    if $('#form_payload_enable_validation_'+position).is(':checked')
      enable_validation = true

    if $('#form_payload_encrypted_'+position).is(':checked')
      encrypted = true

    if $('#form_payload_is_array_'+position).is(':checked')
      is_array = true

    # update value to input
    $('#row_payload_name_'+position).html(name)
    $('#payload_name_'+position).val(name)
    $('#row_payload_ref_name_'+position).html(ref_name)
    $('#payload_ref_name_'+position).val(ref_name)
    $('#row_payload_validation_'+position).html(validation)
    $('#payload_validation_'+position).val(validation)
    $('#row_payload_mapping_'+position).html(mapping)
    $('#payload_mapping_'+position).val(mapping)
    $('#payload_mapping_id_'+position).val(mapping_id)
    $('#row_payload_mandatory_'+position).html(mandatory.toString())
    $('#payload_mandatory_'+position).val(mandatory)
    $('#row_payload_enable_validation_'+position).html(enable_validation.toString())
    $('#payload_enable_validation_'+position).val(enable_validation)
    $('#row_payload_encrypted_'+position).html(encrypted.toString())
    $('#payload_encrypted_'+position).val(encrypted)
    $('#row_payload_is_array_'+position).html(is_array.toString())
    $('#payload_is_array_'+position).val(is_array)
    $('#row_payload_parent_array_'+position).html(parent_array)
    $('#payload_parent_array_'+position).val(parent_array)
    $('#row_payload_description_'+position).html(description)
    $('#payload_description_'+position).val(description)

    return

  # remove payload validation
  $(document).on 'click', '.delete_payload_validation', (event) ->
    position = $(this).attr('id')
    $('row_payload_id_'+position).closest('tr').remove()
    $('#row_payload_validation tr#'+position).remove()
    return

  # if is authentication api
  $('#is_auth').change ->
    if @checked
      $('#auth_token_key_name').attr('required',true)
      $('#insurer_product_api_client_api_id').removeAttr('required')
      $('#insurer_product_api_client_api_id').attr('disabled',true)
      $('#insurer_product_api_client_api_id').val('')
    else
      $('#auth_token_key_name').removeAttr('required')
      $('#insurer_product_api_client_api_id').attr('required',true)
      $('#insurer_product_api_client_api_id').removeAttr('disabled')
    return


  $('#insurer_product_api_api_flavour').on 'change', ->
    if @value == 'Type 2'
    # if selected type 2 API flavor
      $('#insurer_product_api_auth_scheme_name').attr('required',true)
      $('#insurer_product_api_auth_scheme_name').removeAttr('disabled')

      $('#insurer_product_api_credential').attr('required',true)
      $('#insurer_product_api_credential').removeAttr('disabled')

      $('#insurer_product_api_auth_api').removeAttr('required')
      $('#insurer_product_api_auth_api').val('')
      $('#insurer_product_api_auth_api').attr('disabled',true)

    else if @value == 'Type 3'
    # if selected type 3 API flavor

      $('#insurer_product_api_auth_scheme_name').attr('required',true)
      $('#insurer_product_api_auth_scheme_name').removeAttr('disabled')

      $('#insurer_product_api_auth_api').attr('required',true)
      $('#insurer_product_api_auth_api').removeAttr('disabled')

      $('#insurer_product_api_credential').removeAttr('required')
      $('#insurer_product_api_credential').val('')
      $('#insurer_product_api_credential').attr('disabled',true)

    else
    # if selected type 1 API flavor
      $('#insurer_product_api_auth_scheme_name').removeAttr('required')
      $('#insurer_product_api_auth_scheme_name').val('')
      $('#insurer_product_api_auth_scheme_name').attr('disabled',true)

      $('#insurer_product_api_credential').removeAttr('required')
      $('#insurer_product_api_credential').val('')
      $('#insurer_product_api_credential').attr('disabled',true)

      $('#insurer_product_api_auth_api').removeAttr('required')
      $('#insurer_product_api_auth_api').val('')
      $('#insurer_product_api_auth_api').attr('disabled',true)
    return
