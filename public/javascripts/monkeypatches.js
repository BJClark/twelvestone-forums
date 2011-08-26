$(function(){
    _.templateSettings = {
        interpolate : /\{\{(.+?)\}\}/g
    };
    
    Backbone.Model.prototype.toJSON = function() {
        return _(_.clone(this.attributes)).extend({
            'authenticity_token' : window._token
        });
    };
    $.fn.modelAttr = function(modelName) {
        if(typeof this.attr("value") === 'undefined') { return false; }
        
        var reg   = new RegExp("^" + modelName + "\\[(.+?)\\]$"),
            match = false,
            attr  = { };
        
        if((match = this.attr("name").match(reg))) {
            attr[match[1]] = this.attr("value");
            return attr;
        } else {
            return false;
        }
    };
});
