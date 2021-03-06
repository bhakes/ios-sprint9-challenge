//
//  CalorieEntryTableViewController.swift
//  CalorieIntake
//
//  Created by Benjamin Hakes on 2/15/19.
//  Copyright © 2019 Benjamin Hakes. All rights reserved.
//

import UIKit
import SwiftChart
import CoreData

class CalorieEntryTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, ChartDelegate {
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up chart header View
        tableView.tableHeaderView = headerChartController.chart
        headerChartController.chart.delegate = self
        
        // add a footer view so that empty cells don't show up
        tableView.tableFooterView = UIView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateChart(_:)), name: .updateChart, object: nil)

    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CalorieCell", for: indexPath) as? CalorieTableViewCell else { fatalError("Unable to Dequeue cell as CalorieTableViewCell") }
        
        let calorieEvent = fetchedResultsController.object(at: indexPath)
        cell.calorieNumberLabel.text = "\(Int(calorieEvent.numberOfCalories))"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        dateFormatter.locale = Locale(identifier: "en_US")
        
        guard let timestamp = calorieEvent.timestamp else { fatalError("Cell Calorie Event had no associated Timestamp") }
        cell.calorieTimestampLabel.text = dateFormatter.string(from: timestamp)
        
        return cell
    }
 
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            let calorieEntry = fetchedResultsController.object(at: indexPath)
            calorieController.deleteCalorieEntry(for: calorieEntry)
            NotificationCenter.default.post(name: .updateChart, object: self)
            
        }
        
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - Chart Touch Delegate Methods
    
    func didTouchChart(_ chart: Chart, indexes: [Int?], x: Double, left: CGFloat) {
        
    }

    func didFinishTouchingChart(_ chart: Chart) {
        
    }

    func didEndTouchingChart(_ chart: Chart) {
        
    }
//    func didTouchChart(chart: Chart, indexes: Array<Int?>, x: Double, left: CGFloat) {
//        for (seriesIndex, dataIndex) in enumerate(indexes) {
//            if dataIndex != nil {
//                // The series at `seriesIndex` is that which has been touched
//                let value = chart.valueForSeries(seriesIndex, atIndex: dataIndex)
//            }
//        }
//    }
//
    
    // MARK: - FetchedResultsControllerDelegateMethods
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .automatic)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .automatic)
        default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else { return }
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        case .update:
            guard let indexPath = indexPath else { return }
            tableView.reloadRows(at: [indexPath], with: .automatic)
        case .move:
            guard let oldIndexPath = indexPath,
                let newIndexPath = newIndexPath else { return }
            tableView.deleteRows(at: [oldIndexPath], with: .automatic)
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        case .delete:
            guard let indexPath = indexPath else { return }
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    
    
    
    // MARK: - Actions
    @IBAction func addNewCalories(_ sender: Any) {
        let alert = DisplayEntryAlertWindow.getAlterDisplay()
        self.present(alert, animated: true, completion: nil)
        
    }
    
    @objc func updateChart(_ notification: Notification){
        
        headerChartController.updateChartFromCoreData()
        tableView.tableHeaderView = headerChartController.chart
    }
    
    
    
    // MARK: - Properties
    @IBOutlet weak var addCaloriesBarButton: UIBarButtonItem!
    var calorieController: CalorieController = CalorieController()
    var headerChartController: HeaderChartController = HeaderChartController()
    
    lazy var fetchedResultsController: NSFetchedResultsController<CalorieEvent> = {
        
        let fetchRequest: NSFetchRequest<CalorieEvent> = CalorieEvent.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        let moc = CoreDataStack.shared.mainContext
        
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        
        frc.delegate = self
        
        do {
            try frc.performFetch()
        } catch {
            print("Failed to perform fetch on Core Data")
        }
        
        return frc
    }()
    
}
