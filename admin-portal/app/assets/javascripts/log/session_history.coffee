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

  $('#SH_search_log').click (e) ->
    viewAll = false
    table.ajax.reload()
    return

  $('#SH_view_all_log').click (e) ->
    viewAll = true
    table.ajax.reload()
    return

  table = $('#session_history_list').DataTable
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
      url: 'session_history.json'
      data: (d) ->
        d.dateRange = $('#dateRange').val()
        d.viewAll = viewAll
        return
