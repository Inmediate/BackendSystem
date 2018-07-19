$(document).ready ->

  startDate = $('#startDate').val()
  endDate = $('#endDate').val()
  viewAll = false

  $('#dateRange').daterangepicker {
    'linkedCalendars': false
    'showCustomRangeLabel': false
    'startDate': startDate
    'endDate': endDate
    'opens': 'center'
    locale: {
      format: 'DD/MM/YYYY'
    }
  }

  $('#IPA_search_log').click (e) ->
    viewAll = false
    table.ajax.reload()
    return

  $('#IPA_view_all_log').click (e) ->
    viewAll = true
    table.ajax.reload()
    return

  table = $('#log_product_api_list').DataTable
    lengthChange: false
    info: false
    searching: true
    ordering: false
    serverSide: true
    language: {
      emptyTable: 'No logs found',
      zeroRecords: 'No matching logs found'
    }
    ajax:
      url: 'product_api.json'
      data: (d) ->
        d.dateRange = $('#dateRange').val()
        d.viewAll = viewAll
        return
    columnDefs: [
      {
        targets: -1
        visible: false
      }
      {
        targets: -2
        visible: false
      }
    ]

  table.on 'click', 'tr', ->
    d = table.row(this).data()
    #    data = table.row($(this).parents('tr')).data()
    $('#rq_payload').text(d[7])
    $('#rp_payload').text(d[8])
    $('#ipa_modal').modal('show');






