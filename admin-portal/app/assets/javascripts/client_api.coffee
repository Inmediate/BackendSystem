#= require ./application

$(document).ready ->

  $('#client_api_list').DataTable
    lengthChange: false

  $('#add_payload').click ->

    position = $('#row_payload tr').length
    $("#row_payload > tbody ").append('
        <tr id="payload_row">
          <td>'+position+'</td>
          <td><input type="text" class="form-control" name="client_api[payloads][][key_name]" required="required" ></td>
          <td><textarea rows="1" class="form-control" name="client_api[payloads][][validation]"></textarea></td>
          <td><input type="checkbox" value="true" name="client_api[payloads][][mandatory]"></td>
          <td><input type="checkbox" value="true" name="client_api[payloads][][enable_validation]"></td>
          <td><input type="checkbox" value="true" name="client_api[payloads][][is_array]"></td>
          <td><input type="text" class="form-control" name="client_api[payloads][][parent_array]" ></td>
          <td><input type="text" class="form-control" name="client_api[payloads][][description]"></td>
          <td><button type="button" class="btn btn-danger" id="remove_payload">remove</button></td>
        </tr>
      ');


  $('#row_payload').on 'click', '#remove_payload', ->
    $(this).closest('tr').remove()
    return
