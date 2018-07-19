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

  $('#approval_search_log').click (e) ->
    viewAll = false
    table.ajax.reload()
    return

  $('#approval_view_all_log').click (e) ->
    viewAll = true
    table.ajax.reload()
    return

  table = $('#log_approval_list').DataTable
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
      url: 'approval.json'
      data: (d) ->
        d.dateRange = $('#dateRange').val()
        d.viewAll = viewAll
        return
    aoColumnDefs: [
      {
        sClass: 'td-break-word'
        aTargets: [ 3 ]
      }
      {
        sClass: 'td-break-word'
        aTargets: [ 4 ]
      }]


