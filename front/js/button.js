var default_format = "--zebra";
var default_monitor_dir = "/mnt/simulator_out";
var default_script = "fast5_pipeline.sh";
var default_timeout_time_format = "Hours";
var default_timeout_time_value = "";
var default_sim = "off";
var default_real_sim = "off";
var default_sim_dir = "/mnt/zebrafish/zebrafish_test";
var default_time_between_reads = "";
var default_no_reads = "";

reset_default = function() {
    const select_format = document.getElementById("format");
    for (var i = 0; i < select_format.options.length; i ++) {
        if (select_format.options[i].text == default_format) {
            select_format.selectedIndex = i;
        }
    }

    const select_dir = document.getElementById("dir");
    for (var i = 0; i < select_dir.options.length; i ++) {
        if (select_dir.options[i].text == default_monitor_dir) {
            select_dir.selectedIndex = i;
        }
    }

    const select_script_exist = document.getElementById("script-exist");
    for (var i = 0; i < select_script_exist.options.length; i ++) {
        if (select_script_exist.options[i].text == default_script) {
            select_script_exist.selectedIndex = i;
        }
    }

    const select_timeout_format = document.getElementById("timeout-format");
    for (var i = 0; i < select_timeout_format.options.length; i ++) {
        if (select_timeout_format.options[i].text == default_timeout_time_format) {
            select_timeout_format.selectedIndex = i;
        }
    }

    const value_timeout_time = document.getElementById("timeout-time");
    value_timeout_time.value = default_timeout_time_value;

    const real_sim_checkbox = document.getElementById("sim-real");
    if (default_real_sim == "on") {
        real_sim_checkbox.checked = "checked";
    } else if (default_real_sim == "off") {
        real_sim_checkbox.checked = false;
    }

    const select_sim_dir = document.getElementById("sim-dir");
    for (var i = 0; i < select_sim_dir.options.length; i ++) {
        if (select_sim_dir.options[i].text == default_sim_dir) {
            select_sim_dir.selectedIndex = i;
        }
    }

    const value_time_between_reads = document.getElementById("sim-time");
    value_time_between_reads.value = default_time_between_reads;

    const value_no_reads = document.getElementById("sim-read_num");
    value_no_reads.value = default_no_reads;

    const sim_checkbox = document.getElementById("sim");
    if (default_sim == "on") {
        sim_checkbox.checked = "checked";
        
        if (real_sim_checkbox.checked) {
            value_time_between_reads.disabled = "disabled";
        } else {
            value_time_between_reads.disabled = false;
        }

        if (value_time_between_reads.value != "") {
            real_sim_checkbox.disabled = "disabled";
        } else {
            real_sim_checkbox.disabled = false;
        }

        value_no_reads.disabled = false;
        select_sim_dir.disabled = false;

    } else if (default_sim == "off") {
        sim_checkbox.checked = false;

        real_sim_checkbox.disabled = "disabled";
        value_time_between_reads.disabled = "disabled";
        value_no_reads.disabled = "disabled";
        select_sim_dir.disabled = "disabled";
    }
}

window.addEventListener("load", reset_default);

$(document).ready(function() {
    $('.button').click(function() {

        if ($(this).val() == "reset to default options") {
            reset_default();

        } else if ($(this).html() == "i") {
            var id = $(this).attr("id");

            // Get the modal
            var modal = document.getElementById("modal-" + id);

            // Get the button that opens the modal
            var btn = this;

            // Get the <span> element that closes the modal
            var span = document.getElementsByClassName("modal-close-" + id)[0];

            modal.style.display = "block";

            // When the user clicks on <span> (x), close the modal
            span.onclick = function() {
                modal.style.display = "none";
            }

            // When the user clicks anywhere outside of the modal, close it
            window.onclick = function(event) {
                if (event.target == modal) {
                    modal.style.display = "none";
                }
            }
        }

        // var oReq = new XMLHttpRequest(); // New request object
        // oReq.onload = function() {
        //     alert(this.responseText); // testing
        //     // if (this.responseText == 0) {
        //     //     alert("success: analyse began");
        //     // }
        // };
        // oReq.open("get", "analyse.php", true);
        // oReq.send();
    });
});