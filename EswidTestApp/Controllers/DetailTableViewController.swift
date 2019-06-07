//
//  DetailTableViewController.swift
//  EswidTestApp
//
//  Created by Раис Аглиуллов on 05/06/2019.
//  Copyright © 2019 Раис Аглиуллов. All rights reserved.
//

import UIKit
import CoreData

class DetailTableViewController: UITableViewController {
    
    var productList: [List]?
    
    // Свойство для приема данных ячейки из MainVC для открытия старых ячеек и их редактирования
    var product: List!
    
    //Свойство для приема индекса ячейки из MainVC для удаления по кнопке
    var indexPath: IndexPath?
    
    // Свойство для дефолтного изображения
    private var imageIsChanged = false
    
    //MARK: - Outlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var priceTextField: UITextField!
    @IBOutlet weak var countTextField: UITextField!
    
    
    //MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Убирает полосы пустые
        tableView.tableFooterView = UIView()
        
        setupScreen()
    }
    
    //Скрыть клавиатуру
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        nameTextField.resignFirstResponder()
        priceTextField.resignFirstResponder()
        countTextField.resignFirstResponder()
    }
  
    //Сохранение в БД
    private func saveProductItemToCoreData() {
        
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let context = appDelegate.persistentContainer.viewContext
        
        //Если изображение не выбрано будет сохраняться дефолтное
        let imageDefault = imageIsChanged ? imageView.image : #imageLiteral(resourceName: "default-image")
        let imageData = imageDefault?.pngData()
        
        //Что находится в outlets
        let name = nameTextField.text!
        let price = priceTextField.text!
        let count = countTextField.text!
        
        //Обновление продукта
        if product != nil {
            
            let fetchRequest: NSFetchRequest<List> = List.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "name = %@", product.name!)
            
            do {
                let test = try context.fetch(fetchRequest)
                let refreshObject = test[0] as NSManagedObject
                refreshObject.setValue(name, forKey: "name")
                refreshObject.setValue(price, forKey: "price")
                refreshObject.setValue(count, forKey: "count")
                refreshObject.setValue(imageData, forKey: "imageData")
                try context.save()
            } catch {
                print(error)
            }
            
            //Создание нового продукта
        } else {
            
            let entity = NSEntityDescription.entity(forEntityName: "List", in: context)
            
            //Создаю сам объект
            let productItem = NSManagedObject(entity: entity!, insertInto: context) as! List
            
            productItem.name = name
            productItem.price = price
            productItem.count = count
            productItem.imageData = imageData
            
            do {
                productList?.append(productItem)
                try context.save()
            } catch {
                print(error)
            }
        }
    }
    
    //Вызов Alert при пустых textFields
    private func showEmptyAlert() {
        
        let alertController = UIAlertController(title: "Недопустимое название", message: "Заполните поля. Они не должно быть пустым." , preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    //Настройка аутлетов если переход был про ячейке
    private func setupScreen() {
        if product != nil {
            
            //Изображение не будет менять на дефолтное если идет редактирование записи.
            imageIsChanged = true
            
            guard
                let name = product.name,
                let price = product?.price,
                let count = product?.count,
                let imageData = product.imageData else { return }
            
            nameTextField.text = name
            priceTextField.text = price
            countTextField.text = count
            imageView.image = UIImage(data: imageData)
            
            title = name
        }
    }
    
    //Метод для открытия камеры и галереи
    private func chooseImagePicker(sourse: UIImagePickerController.SourceType) {
        
        if UIImagePickerController.isSourceTypeAvailable(sourse) {  //подставляется камера или галерея
            
            let imagePicker = UIImagePickerController()
            
            //13. Чтобы вызвать этот ImagePickerVC ему нужен делегат(т.е кто будет его отрисовывать). Назначаю это самой TableVC(NewPlaceVC).
            imagePicker.delegate = self
            
            //8.2позволяет масштабировать изображение
            imagePicker.allowsEditing = true
            
            imagePicker.sourceType = sourse
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    //MARK: - TableView Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row == 0 {
            
            print("212")
            //Добавляю Алерт
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            let actionCamera = UIAlertAction(title: "Камера", style: .default) { (_) in
                // Открывает камеру
                self.chooseImagePicker(sourse: .camera)
            }
            
            let actionPhotoGalery = UIAlertAction(title: "Галерея", style: .default) { (_) in
                // Открывает галерею
                self.chooseImagePicker(sourse: .photoLibrary)
            }
            
            //Кнопка отмены и добавляю экшены
            let actionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            actionSheet.addAction(actionCamera)
            actionSheet.addAction(actionPhotoGalery)
            actionSheet.addAction(actionCancel)
            
            present(actionSheet, animated: true, completion: nil )
            
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        
    }
    
    //MARK: - Actions
    //Сохранение в CoreData
    @IBAction func saveButton(_ sender: Any) {
        
        if nameTextField.text!.isEmpty || nameTextField.text == "" || priceTextField.text!.isEmpty || priceTextField.text == "" || countTextField.text!.isEmpty || countTextField.text == "" {
            showEmptyAlert()
        } else {
            
            saveProductItemToCoreData()
            
            NotificationCenter.default.post(name: NSNotification.Name("ProductItemSaveOrDelete"), object: nil)
            navigationController?.popViewController(animated: true)
        }
    }
    
    //Удаление из CoreData
    @IBAction func deleteButton(_ sender: UIButton) {
        //Выбранная ячейка
        guard let deleteProduct = product else { return }
        
        // Добираюсь до АпДелегат. Нужно будет для свойства СейвКонтекст
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        // Получаю сам контекст
        let context = appDelegate.persistentContainer.viewContext
        
        //Удаление из массива
        productList?.remove(at: indexPath!.row)
        
        context.delete(deleteProduct)
        
        do {
            try context.save()

        } catch {
            print(error)
        }
        
        //Для обновления таблицы
        NotificationCenter.default.post(name: NSNotification.Name("ProductItemSaveOrDelete"), object: nil)
        navigationController?.popViewController(animated: true)
    }
}

//MARK: - Extensions
//Чтобы была возможность сохранять снятое или выбранное изобр
extension DetailTableViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // вызывается при окончание редактировании медиа (пример масштабирование).
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        //передаю в аутлет отредакт. изображение
        imageView.image = info[.editedImage] as? UIImage
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        // Меняю imageIsChanged т.к пользователь выбрал свое и не нужно дефолтное изображение
        imageIsChanged = true
        
        dismiss(animated: true, completion: nil)
    }
}

extension DetailTableViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        nameTextField.resignFirstResponder()
        return true
    }
}
