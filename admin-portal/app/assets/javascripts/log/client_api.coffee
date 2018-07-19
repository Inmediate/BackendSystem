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

  $('#CA_search_log').click (e) ->
    viewAll = false
    table.ajax.reload()
    return

  $('#CA_view_all_log').click (e) ->
    viewAll = true
    table.ajax.reload()
    return

  table = $('#log_client_api_list').DataTable
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
      url: 'client_api.json'
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
    $('#rq_payload').text(d[8])
    $('#rp_payload').text(d[9])
    $('#ca_modal').modal('show');

