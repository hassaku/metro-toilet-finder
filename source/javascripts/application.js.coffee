#= require jquery
#= require foundation
#= require social-likes

$(document).foundation()

#server_url = 'http://0.0.0.0:9292'
server_url = 'http://metro-toilet-finder.herokuapp.com'

# 駅の取得
$('select[name=railway]').on 'change', ->
  $('select[name=stop] > option').remove()
  $('select[name=destination] > option').remove()
  return unless $(@).val()

  $.ajax "#{server_url}/stations?railway=#{$(@).val()}",
    type: 'GET'
    dataType: 'json'
    error: (jqXHR, textStatus, errorThrown) ->
      alert "Network Error"
    success: (data, textStatus, jqXHR) ->
      $('select[name=stop]').append($('<option>').html(option).val(option)) for option in data
      $('select[name=destination]').append($('<option>').html(option).val(option)) for option in data

# 各駅のトイレ情報の取得ページヘ遷移
$('#search').on 'click', ->
  railway = $('select[name=railway]').val()
  stop = $('select[name=stop]').val()
  destination = $('select[name=destination]').val()
  window.location.href = "/toilets.html?railway=#{railway}&stop=#{stop}&destination=#{destination}"

# ページ遷移後にデータを取得してページを構築
accordion = (content) ->
  """
  <dl class="accordion" data-accordion>
    #{content}
  </di>
  """

panelClosure = ->
  num = 0

  return panel = (title, content) ->
    num++
    """
    <dd class="accordion-navigation">
      <a href="#panel#{num}">#{title}</a>
        <div id="panel#{num}" class="content">
          #{content}
        </div>
      </a>
    </dd>
    """

departuresList = (departures) ->
  list = ""
  for departure in departures
    list += "<li>#{departure["departure_time"]}"
    list += " (#{departure["lost_time"]} 分遅れ)</li>\n" if departure["lost_time"]
  "<ol>\n#{list}\n</ol>\n"

toiletsList = (toilets) ->
  list = ""
  for toilet in toilets
    list += "<li>#{toilet["place"]}</li>\n"
  "<ul>\n#{list}\n</ul>\n"

map = (station_name) ->
  return unless station_name
  station_hyphen_case = station_name.replace(/([A-Z])/g, "-$1").toLowerCase().replace(/^-/, "")
  """
  <a href="#" data-reveal-id="myModal">構内マップを見る</a>
  <div id="myModal" class="reveal-modal full-screen" data-reveal>
    <img src="http://www.tokyometro.jp/station/#{station_hyphen_case}/yardmap/images/yardmap.gif" />
    <a class="close-reveal-modal">&#215;</a>
  </div>
  """

$ ->
  return unless location.pathname.trim() is "/toilets.html"

  $.ajax "#{server_url}/toilets#{location.search}",
    type: 'GET'
    dataType: 'json'
    error: (jqXHR, textStatus, errorThrown) ->
      console.log "Network Error"
      window.location.href = "/"
    success: (data, textStatus, jqXHR) ->
      $('.fa-spin').remove()

      # TODO: Vue.js使ってリファクタリング
      panel = panelClosure()
      panelsElements = ""
      for stop in data["stops"]
        list = "<h4>出発時刻（降車時のロスタイム）</h4>\n"
        list += departuresList(stop["departures"])
        list += "<h4>トイレ</h4>\n"
        list += toiletsList(stop["toilets"])
        list += map(stop["name"])
        panelsElements += panel(stop["name"], list)
      el = accordion(panelsElements)

      $('#toilets').empty()
      $('#toilets').append $(el)
      $(document).foundation() # accordionを動作させるため
