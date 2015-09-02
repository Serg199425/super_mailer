var dispatcher = new WebSocketRails('localhost:3001/websocket')
var letters_count
dispatcher.bind('letters.updated', function(response) {
  if (response.error)
    $('.letters-info').html('<div class="alert alert-danger centered" role="alert">Updating is Failed. Try later</div>');
  letters_count = response.letters_count
  if (letters_count > 0) {
    update_content();
  } else {
    $('.letters-info').html('<div class="alert alert-info centered" role="alert">You have not new mails</div>');
  }
});

function update_content() {
  return $.getScript(gon.letters_inbox_path, function() {
    $('.letters-info').html('<div class="alert alert-info centered" role="alert">You haven new ' +  
      letters_count + ' mail(s)</div>');
  });
}

function refresh_letters() {
  return $.getScript(gon.letters_refresh_path);
}