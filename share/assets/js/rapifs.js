// This custom JS is just here as an example of how to extend RapidApp
// module functionality in general (one of many possible approaches)

Ext.ns('Ext.ux.RapiFs');


Ext.ux.RapiFs.FileTree = Ext.extend(Ext.ux.RapidApp.AppTree,{

  initComponent: function() {
  
    if(this.dblclick_download) {
      this.on('dblclick',function(node,e) {
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
      },this);
    }
  
    Ext.ux.RapidApp.AppTree.superclass.initComponent.call(this);
  }

});
Ext.reg('rapifs-filetree',Ext.ux.RapiFs.FileTree);
