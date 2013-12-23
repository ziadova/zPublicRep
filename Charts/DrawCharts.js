var colors = "#0000FF,#A52A2A,#D2691E,#DC143C,#008B8B,#006400,#8B008B,#8A2BE2"

function getUrlVars() {
    var vars = [], hash;
    var hashes = window.location.href.slice(window.location.href.indexOf('?') + 1).split('&');
    for (var i = 0; i < hashes.length; i++) {
        hash = hashes[i].split('=');
        vars.push(hash[0]);
        vars[hash[0]] = hash[1];
    }
    return vars;
}
var values = [];
function drawChart() {
    values = getUrlVars();
    b.dir = values["dir"];
    document.getElementById("title").innerHTML = decodeURIComponent(values["title"].toString().split("%20").join(" "));
    if (values["type"] == "pie") {
        draw_pie_chart();
    }
    else if (values["type"] == "bar") {
        draw_bar_chart();
    }

}

function draw_pie_chart() {

    var color = colors.split(',')
    var count = (values.length - 3) / 2;
    var pieData_st = '[';
    var tableContent = "<table>";
    for (var i = 0; i < count; i++) {

        if (i == 0) {
            pieData_st += '{"value": ' + values["value" + (i + 1).toString()] + ',"color": "' + color[i] + '"}';
        }
        else {
            pieData_st += ',{"value": ' + values["value" + (i + 1).toString()] + ',"color": "' + color[i] + '"}';
        }
        var styleColor = 'background-color:'+color[i]+';';
        tableContent += "<tr ><td width='75' style='" + styleColor + "'></td><td>" + decodeURIComponent(values["lbl" + (i + 1).toString()]) + "</td><td>" + values["value" + (i + 1).toString()] + "</td></tr>";


    }
    tableContent += "</table>";
    pieData_st += ']';

    document.getElementById("table").innerHTML = tableContent;

    //var pieData_st = '[{"value": ' + values["value1"] + ',"color": "'+color[0]+'"},{"value": ' + values["value2"] + ',"color": "'+color[1]+'"}]';
    var pieData = $.parseJSON(pieData_st);
    var myPie = new Chart(document.getElementById("canvas").getContext("2d")).Pie(pieData);
}

function draw_bar_chart() {
    var color = colors.split(',')

    var count = (values.length - 4);
    var barChartData_str = '{"labels": [' + decodeURIComponent(values["lbl"]) + '],"datasets": [';
    for (var i = 0; i < count; i++) {

        if (i == 0) {
            barChartData_str += '{"fillColor": "' + color[i] + '","strokeColor": "' + color[i] + '","data": [' + values["value" + (i + 1).toString()] + ']}';
        }
        else {
            barChartData_str += ',{"fillColor": "' + color[i] + '","strokeColor": "' + color[i] + '","data": [' + values["value" + (i + 1).toString()] + ']}';
        }
    }

    barChartData_str += ']}';
    
    var barChartData = $.parseJSON(barChartData_str);
  
    var myLine = new Chart(document.getElementById("canvas").getContext("2d")).Bar(barChartData);
}
