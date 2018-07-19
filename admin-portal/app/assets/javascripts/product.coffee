#= require ./application

$(document).ready ->
  $('#product_list').DataTable
    lengthChange: false

  $('#product_name').on 'input', ->
    name = $('#product_name').val().replace(/\s+/g,"-").toLowerCase()
    $('#product_code').val(name)
    return

