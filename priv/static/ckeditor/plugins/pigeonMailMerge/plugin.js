CKEDITOR.plugins.add( 'pigeonMailMerge', {
    init: function( editor ) {
    	
    	function genCommand( name ) {
    	    return function( editor ) {
    	        editor.insertHtml( "{{#" + name +"#}}" );
    	    };  
    	}

    	for (i = 0; i < List.length; i++) { 
	    	
    		var commandName = List[i]+"_CMM";
    		var label = List[i];

    	    editor.addCommand( commandName, {exec : genCommand( label)} );
    		
    		editor.ui.addButton( label, {
	    	    label: label, 
	    	    command: commandName,
	    	    toolbar: 'MailMerge'
	    	});
    	}
    }
});

CKEDITOR.document.appendStyleSheet(CKEDITOR.plugins.getPath('pigeonMailMerge')+"/css/file.css");
