#= require ./application

$(document).ready ->
#  $('#insurer_product_api_list').DataTable
#    lengthChange: false

  $('#insurer_mapping_list').DataTable
    lengthChange: false

  type = ''
  product_id = ''

  $('#ip_all').click (e) ->
    e.preventDefault()
    type = ''
    table.ajax.reload()
    return

  $('#ip_auth_api').click (e) ->
    e.preventDefault()
    type = 'auth_api'
    table.ajax.reload()
    return

  $(".result-code-option").click (e) ->
    e.preventDefault()
    type = 'product'
    $("#ip_product").val($(this).data("result-code"));
    table.ajax.reload()
    return

  table = $('#insurer_product_api_list').DataTable
    lengthChange: false
    info: false
    searching: true
    ordering: true
    serverSide: true
    language: {
      emptyTable: 'No logs found',
      zeroRecords: 'No matching logs found'
    }
    ajax:
      url: 'edit.json'
      data: (d) ->
        d.insurer_id = $('#insurer_id').val()
        d.type = type
        d.product_id = $("#ip_product").val()
        type = ''
        product_id = ''
        return
    columnDefs: [
      {
        targets: -1,
        data: null,
        orderable: false
        defaultContent: "<a href='#'><i class=\"fas fa-edit\"></i></a >"
      }

    ]

  $('#insurer_product_api_list tbody').on 'click', 'a', ->
    data = table.row($(this).parents('tr')).data()
    $(this).attr("href", '/insurer/'+$('#insurer_id').val()+'/api/'+data[11]+'/'+data[9]);
    return