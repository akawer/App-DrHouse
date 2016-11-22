//
//  FilterTableViewController.swift
//  DrHouse
//
//  Created by Aaron Kawer on 11/19/16.
//  Copyright © 2016 Aaron Kawer. All rights reserved.
//

import UIKit

struct Filters {
    let tags : [String]
    let startDate: Date?
    let endDate: Date?
}

protocol FilterTableViewControllerDelegate : class {
    func didApply(filters: Filters)
}

class FilterTableViewController: UITableViewController {
    
    // -------------------------
    // MARK - Properties
    // -------------------------
    
    let startDatePicker = UIDatePicker()
    let endDatePicker = UIDatePicker()
    weak var delegate : FilterTableViewControllerDelegate?
    
    // -------------------------
    // MARK - Outlets
    // -------------------------

    @IBOutlet weak var medicineCell: UITableViewCell!
    @IBOutlet weak var symptomCell: UITableViewCell!
    @IBOutlet weak var vaccineCell: UITableViewCell!
    
    @IBOutlet weak var startDateTextField: UITextField!
    @IBOutlet weak var endDateTextField: UITextField!
    
    // -------------------------
    // MARK - Lifecycle
    // -------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startDateTextField.inputView = startDatePicker
        endDateTextField.inputView = endDatePicker
        startDatePicker.datePickerMode = .date
        endDatePicker.datePickerMode = .date
        
        endDatePicker.addTarget(self, action: #selector(FilterTableViewController.endDatePickerValueChanged(datePicker:)), for: .valueChanged)
        startDatePicker.addTarget(self, action: #selector(FilterTableViewController.startDatePickerValueChanged(datePicker:)), for: .valueChanged)
    }

    // -------------------------
    // MARK - TableView
    // -------------------------
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            // Mark the selected tag
            if let cell = tableView.cellForRow(at: indexPath) {
                
                if cell.accessoryType == .none {
                    cell.accessoryType = .checkmark
                } else {
                    cell.accessoryType = .none
                }
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // -------------------------
    // MARK - Actions
    // -------------------------

    @IBAction func doneTapped(_ sender: Any) {
        // Save the filters
        
        // Find selected tags
        let cells = [medicineCell, symptomCell, vaccineCell]
        let tags = ["Med", "Sym", "Vac"]
        var selectedTags = [String]()
        var i = 0
        for cell in cells {
            if cell?.accessoryType == .checkmark {
                selectedTags.append(tags[i])
            }
            i += 1
        }
        
        // If the textfields have not been filled, do not filter by date
        let startDate : Date? = startDateTextField.text!.characters.count == 0 ? nil : startDatePicker.date
        let endDate : Date? = endDateTextField.text!.characters.count == 0 ? nil : endDatePicker.date
        
        // Apply the filters
        
        let filters = Filters(tags: selectedTags, startDate: startDate, endDate: endDate)
        delegate?.didApply(filters: filters)
        
        // Dismiss the view
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func formatted(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    func endDatePickerValueChanged(datePicker: UIDatePicker) {
        endDateTextField.text = formatted(date: datePicker.date)
    }
    func startDatePickerValueChanged(datePicker: UIDatePicker) {
        startDateTextField.text = formatted(date: datePicker.date)
    }
    
}
