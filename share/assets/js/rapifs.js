// This custom JS is just here as an example of how to extend RapidApp
// module functionality in general (one of many possible approaches)

Ext.ns('Ext.ux.RapiFs.Plugin');

Ext.ux.RapiFs.Plugin.DblclickDownload = Ext.extend(Ext.util.Observable,{

  init: function(tree) {
  
    if(tree.dblclick_download) {
      tree.on('dblclick',function(node,e) {
        try{
          var path = node.attributes.loadContentCnf.autoLoad.url;
          if(path && node.leaf) {
            var url = [
              Ext.ux.RapidApp.AJAX_URL_PREFIX||'',
              path, '?method=download'
            ].join('');
            
            document.location.href = url;
          }
        }catch(e){};
      },tree);
    }
  
  }

});
Ext.preg('rapifs-dblclick-download',Ext.ux.RapiFs.Plugin.DblclickDownload);
