//
//  ChartView.swift
//  StocksApp
//
//  Created by Alfian Losari on 26/11/22.
//  Optimized by migsmush on May 19th, 2025.
//

import Charts
import SwiftUI
import XCAStocksAPI

struct ChartView: View {
    
    let data: ChartViewData
    @StateObject var vm: ChartViewModel
    @State var dragIndex: Int? = nil
    
    var body: some View {
        VStack {
//            if let dragIndx = dragIndex {
//                Text(data.items[dragIndx].formattedDate)
//                    .font(.caption)
//                    .padding(.bottom, 5)
//            }
            ZStack {
                chart
                    .chartXAxis { chartXAxis }
                    .chartXScale(domain: data.xAxisData.axisStart...data.xAxisData.axisEnd)
                    .chartYAxis { chartYAxis }
                    .chartYScale(domain: data.yAxisData.axisStart...data.yAxisData.axisEnd)
                    .chartPlotStyle { chartPlotStyle($0) }
                chartRulemarks
                    .chartXAxis { chartXAxis }
                    .chartXScale(domain: data.xAxisData.axisStart...data.xAxisData.axisEnd)
                    .chartYAxis { chartYAxis }
                    .chartYScale(domain: data.yAxisData.axisStart...data.yAxisData.axisEnd)
                    .chartPlotStyle { chartPlotStyle($0) }
                    .chartOverlay { proxy in
                        GeometryReader { gProxy in
                            Rectangle().fill(.clear).contentShape(Rectangle())
                                .gesture(DragGesture(minimumDistance: 0)
                                    .onChanged { onChangeDrag(value: $0, chartProxy: proxy, geometryProxy: gProxy) }
                                    .onEnded { _ in
                                        vm.isDragging = false
                                        self.dragIndex = nil
                                    }
                                )
                        }
                    }
            }
        }
    }
    
    private var chart: some View {
        Chart(data.items) { item in
                LineMark(
                    x: .value("Time", item.index),
                    y: .value("Price", item.value))
                .foregroundStyle(vm.foregroundMarkColor)
                
                AreaMark(
                    x: .value("Time", item.index),
                    yStart: .value("Min", data.yAxisData.axisStart),
                    yEnd: .value("Max", item.value)
                )
                .foregroundStyle(LinearGradient(
                    gradient: Gradient(colors: [
                        vm.foregroundMarkColor,
                        .clear
                    ]), startPoint: .top, endPoint: .bottom)
                ).opacity(0.3)
        }
    }
    
    private var chartRulemarks: some View {
        Chart {
            if let previousClose = data.previousCloseRuleMarkValue {
                RuleMark(y: .value("Previous Close", previousClose))
                    .lineStyle(.init(lineWidth: 0.1, dash: [2]))
                    .foregroundStyle(.gray.opacity(0.3))
                
            }
            if let dragIndx = self.dragIndex {
                    RuleMark(x: .value("date", data.items.count / 2))
                        .lineStyle(.init(lineWidth: 0))
                        .annotation {
                            Text(data.items[dragIndx].formattedDate)
                                .font(.system(size: 14))
                                .padding(.bottom, 35)
                        }
                        .foregroundStyle(.cyan)
                    RuleMark(x: .value("Selected timestamp", dragIndx))
                        .lineStyle(.init(lineWidth: 1))
                        .annotation {
                            Text("\(data.items[dragIndx].value, specifier: "%.2f")")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                        }
                        .foregroundStyle(.cyan)
            }
        }
    }
    
    private var chartXAxis: some AxisContent {
        AxisMarks(values: .stride(by: data.xAxisData.strideBy)) { value in
            if let text = data.xAxisData.map[String(value.index)] {
                AxisGridLine(stroke: .init(lineWidth: 0.3))
                AxisTick(stroke: .init(lineWidth: 0.3))
                AxisValueLabel(collisionResolution: .greedy()) {
                    Text(text)
                        .foregroundColor(Color(uiColor: .label))
                        .font(.caption.bold())
                }
            }
            
            
        }
    }
    
    private var chartYAxis: some AxisContent {
        AxisMarks(preset: .extended, values: .stride(by: data.yAxisData.strideBy)) { value in
            if let y = value.as(Double.self),
               let text = data.yAxisData.map[y.roundedString] {
                AxisGridLine(stroke: .init(lineWidth: 0.3))
                AxisTick(stroke: .init(lineWidth: 0.3))
                AxisValueLabel(anchor: .topLeading, collisionResolution: .greedy) {
                    Text(text)
                        .foregroundColor(Color(uiColor: .label))
                        .font(.caption.bold())
                }
            }
        }
    }
    
    
    private func chartPlotStyle(_ plotContent: ChartPlotContent) -> some View {
        plotContent
            .frame(height: 200)
            .overlay {
                Rectangle()
                    .foregroundColor(.gray.opacity(0.5))
                    .mask(ZStack {
                        VStack {
                            Spacer()
                            Rectangle().frame(height: 1)
                        }
                        
                        HStack {
                            Spacer()
                            Rectangle().frame(width: 0.3)
                        }
                    })
            }
    }
    
    private func onChangeDrag(value: DragGesture.Value, chartProxy: ChartProxy, geometryProxy: GeometryProxy) {
        let xCurrent = value.location.x - geometryProxy[chartProxy.plotAreaFrame].origin.x
        if let index: Double = chartProxy.value(atX: xCurrent),
           index >= 0,
           Int(index) <= data.items.count - 1 {
            self.dragIndex = Int(index)
            if !vm.isDragging {
                vm.isDragging = true
            }
        }
    }
    
}

struct ChartView_Previews: PreviewProvider {
    
    static let allRanges = ChartRange.allCases
    static let oneDayOngoing = ChartData.stub1DOngoing
    
    static var previews: some View {
        ForEach(allRanges) {
            ChartContainerView_Previews(vm: chartViewModel(range: $0, stub: $0.stubs), title: $0.title)
        }
        
        ChartContainerView_Previews(vm: chartViewModel(range: .oneDay, stub: oneDayOngoing), title: "1D Ongoing")
        
    }
    
    static func chartViewModel(range: ChartRange, stub: ChartData) -> ChartViewModel {
        var mockStocksAPI = MockStocksAPI()
        mockStocksAPI.stubbedFetchChartDataCallback = { _ in stub }
        let chartVM = ChartViewModel(ticker: .stub, apiService: mockStocksAPI)
        chartVM.selectedRange = range
        return chartVM
    }
    
}

#if DEBUG
struct ChartContainerView_Previews: View {
    
    @StateObject var vm: ChartViewModel
    let title: String
    
    var body: some View {
        VStack {
            Text(title)
                .padding(.bottom)
            if let chartViewData = vm.chart {
                ChartView(data: chartViewData, vm: vm)
            }
        }
        .padding()
        .frame(maxHeight: 272)
        .previewLayout(.sizeThatFits)
        .previewDisplayName(title)
        .task { await vm.fetchData() }
    }
    
}

#endif
