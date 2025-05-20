This repository was created to add optimizations to the stocks app created by https://github.com/alfianlosari
in his tutorial https://www.youtube.com/watch?v=uI3Q9qyIs-Y&t=922s&ab_channel=XcodingwithAlfian

His repo with the code for the tutorial can be found here:
https://github.com/alfianlosari/stocksapptutorial

alfianlosari's tutorial provides a step-by-step guide on how to manually re-create the core functionalities offered in Apple's native Stocks iOS

As I followed the tutorial, I noticed that the rulemark displayed in the ChartView when dragging accross the chart starts to get really choppy
when the number of items displayed in the chart gets somewhat large (100+ items slows down performance).

The following files were modified in order to prevent the choppyness when performing a drag gesture over the ChartView:

## ChartView:
- removed all references to vm.selectedX (modifying vm.selectedX on each drag change causes an entire re-render of ChartView due to @ObservedObject ChartViewModel)
- use vm.isDragging to hide the date picker in StockTickerView, only set to true / false at the start / end of the drag gesture respectively
- use a state variable for the drag index, using state variable instead of watching a var published by vm prevents the entire view from getting re-constructed
- display the formattedDate directly in ChartView since ChartViewModel no longer has access to the drag index, which StockTickerView is dependent on to display date string
- clean up the loop for plotting chart data
- stop using the Double extension roundedString and simply use string formatting specifier directly when displaying the price Double during drag

## ChartViewModel
- added new published var isDragging, which StockTickerView is dependent on to show / hide DateRangePickerView
- assign the two new fields in ChartViewData 'index' and 'formattedDate' in xAxisChartDataAndItems function
- stop computing the formattedDate string during drag gesture and simply assign it directly to the ChartViewData's ChartViewItem
## StockTickerView
- show / hide DateRangePickerView based on vm.isDragging instead of vm.selectedX
- remove date displayed on drag gesture since ChartView is now responsible for displaying that
## ChartViewData
- add two new fields to ChartViewItem 'index' and formattedDate'
- index allows us to to be able to clean up the chart plotting loop in ChartView so we don't have to enumerate
- formattedDate allows us to compute the date string in ahead of time instead of on the fly as we drag
