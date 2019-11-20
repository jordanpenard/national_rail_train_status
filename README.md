# national_rail_train_status
This TCL/TK app reports the next X number of trains from and to the provided station name. It make use of the OpenLDBWS API (https://lite.realtime.nationalrail.co.uk/OpenLDBWS/) in order to query live train status.

## Prerequisite
For this software to run, you will need to request an API key from national rail (http://realtime.nationalrail.co.uk/OpenLDBWSRegistration/?_ga=2.221254744.1916304910.1574264913-320964120.1558454901) that you will need to put in the `request_template.xml` file.

## Usage example
If you want to display the next 4 trains from Kings Langley (KGL) to Watford Junction (WFJ) :
```
./train_status.tcl KGL WFJ 4
```

