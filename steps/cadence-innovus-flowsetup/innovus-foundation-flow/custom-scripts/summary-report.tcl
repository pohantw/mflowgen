#=========================================================================
# summary-report.tcl
#=========================================================================
# Script used to customize the summary report step
#
# Author : Christopher Torng
# Date   : March 26, 2018

summaryReport -noHtml -outfile $vars(rpt_dir)/$vars(step).summaryReport.rpt

# delete existing route blockage and halo to prevent false alarm in DRC/connectivity checking in innovus
deleteRouteBlk -all
deleteHaloFromBlock -allBlock
