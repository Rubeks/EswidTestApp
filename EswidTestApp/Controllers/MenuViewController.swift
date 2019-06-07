//
//  ViewController.swift
//  EswidTestApp
//
//  Created by Раис Аглиуллов on 05/06/2019.
//  Copyright © 2019 Раис Аглиуллов. All rights reserved.
//

import UIKit
import CoreData

class MenuViewController: UIViewController {
    
    //Массив данных из CoreData
    var productList: [List]?
    
    //Для сохранения индекса выбранной ячейки и передача его в DetailVC для возможности удаления
    var selectedIndex: IndexPath?
    
    //SearchController
    private let searchController = UISearchController(searchResultsController: nil)
    private var filteredProductList = [List]()
    
    //Свойство которое хранит не является ли поиск пустым
    private var searchBarIsEmpty: Bool {
        guard let text = searchController.searchBar.text else { return false }
        return text.isEmpty //т.е если пустая то вернется true
    }
    
    //Отслеживание активации поискового запроса
    private var isFiltering: Bool {
        return searchController.isActive && !searchBarIsEmpty
    }
    
    //MARK: - Outlers
    @IBOutlet weak var tableView: UITableView!
    
    //MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadDataFromCoreData()
        
        //Наблюдение за изменением в CoreData
        NotificationCenter.default.addObserver(self, selector: #selector(updateTableView), name: NSNotification.Name(rawValue: "ProductItemSaveOrDelete"), object: nil)
        
        //SearchControoler setup
        //Подписка под протокол
        searchController.searchResultsUpdater = self
        
        //Взаимодействие с отфильтрованным контентом
        searchController.obscuresBackgroundDuringPresentation = false
        
        searchController.searchBar.placeholder = "Поиск"
        navigationItem.searchController = searchController
        
        //Позволяет отпустить строку поиска при переходе на другой экран
        definesPresentationContext = true
    }
    
    //Подгрузка из CoreData
    private func loadDataFromCoreData() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<List> = List.fetchRequest()
        
        do {
            productList = try context.fetch(fetchRequest)
        } catch {
            print(error)
        }
    }
    
    //Обновление таблицы при новой записи в DetailVC
    @objc func updateTableView() {
        loadDataFromCoreData()
        self.tableView.reloadData()
    }
    
    //Настройка ячейки
    private func configureCell(cell: MenuTableViewCell, indexPath: IndexPath) {
        
        //Если в поиске что-то есть
        if isFiltering {
            guard
                let itemName = filteredProductList[indexPath.row].name,
                let itemPrice = filteredProductList[indexPath.row].price,
                let itemCount = filteredProductList[indexPath.row].count,
                let itemImage = filteredProductList[indexPath.row].imageData
                else { return }
            
            cell.nameLabel.text = "Наименование: " + itemName
            cell.priceLabel.text = "Цена: " + itemPrice
            cell.countLabel.text = "Количество: " + itemCount
            cell.customImageView.image = UIImage(data: itemImage)
            
            //Если поиск пустой
        } else {
            guard
                let itemName = productList?[indexPath.row].name,
                let itemPrice = productList?[indexPath.row].price,
                let itemCount = productList?[indexPath.row].count,
                let itemImage = productList?[indexPath.row].imageData
                else { return }
            
            
            cell.nameLabel.text = "Наименование: " + itemName
            cell.priceLabel.text = "Цена: " + itemPrice
            cell.countLabel.text = "Количество: " + itemCount
            cell.customImageView.image = UIImage(data: itemImage)
        }
    }
    
    //Настройка передачи состояния
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "cellSelected" {
            
            guard let index = tableView.indexPathForSelectedRow else { return }
            
            let product: List?
            
            if isFiltering {
                product = filteredProductList[index.row]
            } else {
                product = productList?[index.row]
            }
            
            let detailCV = segue.destination as! DetailTableViewController
            
            detailCV.product = product
            detailCV.indexPath = selectedIndex
        }
    }
    
    //Создание нового товара
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        
        //Переход с задержкой
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.performSegue(withIdentifier: "addButtonPressed", sender: nil)
        }
    }
}

//MARK: - -----------
//MARK: - DataSourse
extension MenuViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
     
        if isFiltering {
            return filteredProductList.count
        }
        return productList!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? MenuTableViewCell {
            configureCell(cell: cell, indexPath: indexPath)
            return cell
        }
        return UITableViewCell()
    }
}
//MARK: - Delegate
extension MenuViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //Снятие выделения
        tableView.deselectRow(at: indexPath, animated: true)
        
        //Сохранение индекса выбранной ячейки
        selectedIndex = indexPath
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        //Выбранная ячейка
        guard let deleteProduct = productList?[indexPath.row], editingStyle == .delete else { return }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        //Удаление из массива
        productList?.remove(at: indexPath.row)
        
        context.delete(deleteProduct)
        
        self.tableView.beginUpdates()
        
        do {
            try context.save()
            tableView.deleteRows(at: [indexPath], with: .automatic)
        } catch {
            print(error)
        }
        self.tableView.endUpdates()
    }
}

extension MenuViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filteredContentForSearchText(searchController.searchBar.text!)
    }
    
    //Логика сортировки
    private func filteredContentForSearchText(_ searchText: String) {
        
        guard let products = productList else { return }
        
        filteredProductList = products.filter({ (product: List) -> Bool in
            return (product.name?.lowercased().contains(searchText.lowercased()))!
        })
        tableView.reloadData()
    }
}


