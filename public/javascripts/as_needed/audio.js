function loadAudioPlayer(url, dom_id, width) {
  var s1 = new SWFObject('/embed/player.swf','ply',width,'24','9','#ffffff');
  s1.addParam('allowfullscreen','false');
  s1.addParam('allowscriptaccess','always');
  s1.addParam('wmode','opaque');
  s1.addVariable('file', url);
  s1.addVariable('type','sound');
  s1.write(dom_id);
}