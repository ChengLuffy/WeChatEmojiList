//
//  ViewController.swift
//  WeChatEmoji
//
//  Created by 成殿 on 2019/7/3.
//  Copyright © 2019 成殿. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var copyAvaliable = UserDefaults.standard.bool(forKey: "CopyAvaliable")
    var copyWxCode = UserDefaults.standard.bool(forKey: "CopyWxCode")
    var showAlert = UserDefaults.standard.bool(forKey: "ShowAlert")
    
    lazy var dataSource: [Model] = {
        let path = Bundle.main.path(forResource: "emoji_zh", ofType: "json")
        let data = try! Data.init(contentsOf: URL.init(fileURLWithPath: path!), options: Data.ReadingOptions.alwaysMapped)
        let arr = try! JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as! NSArray
        
        var dataSource = [Model]()
        
        for dict in arr {
            let model = Model.init(data: dict as! [String : String])
            dataSource.append(model)
        }
        
        return dataSource
    }()
    
    var searchResults: [Model] = [Model]()
    
    lazy var searchC: UISearchController = {
        weak var weakSelf = self
        let searchC = UISearchController(searchResultsController: nil)
        searchC.searchResultsUpdater = self
        searchC.delegate = self
        searchC.obscuresBackgroundDuringPresentation = false;
        searchC.searchBar.placeholder = "请输入你想搜索的表情关键词"
        searchC.searchBar.autocapitalizationType = .none
        return searchC
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        collectionView.register(CollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).estimatedItemSize = CGSize.init(width: 65, height: 100)
        
        navigationItem.searchController = searchC
        navigationItem.searchController?.hidesNavigationBarDuringPresentation = false
        navigationItem.hidesSearchBarWhenScrolling = true
        
        NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: UserDefaults.standard, queue: OperationQueue.main) { (noti) in
            let center = noti.object as! UserDefaults
            self.copyWxCode = center.bool(forKey: "CopyWxCode")
            self.copyAvaliable = center.bool(forKey: "CopyAvaliable")
            self.showAlert = center.bool(forKey: "ShowAlert")
        }
        
    }
    
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searchC.isActive ? searchResults.count : dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CollectionViewCell
        let model = searchC.isActive ? searchResults[indexPath.item] : dataSource[indexPath.item]
        cell.emojiLabel.text = model.name
        cell.emojiCodeLabel.text = model.wx_code
        cell.emojiImageView.image = UIImage.init(named: model.imageName)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let model = searchC.isActive ? searchResults[indexPath.item] : dataSource[indexPath.item]
        if copyAvaliable {
            UIPasteboard.general.string = copyWxCode ? model.wx_code : model.zh_code
        }
        if showAlert {
            let alertC = UIAlertController(title: model.name, message: "中文编码\n" + model.zh_code + "\n\n" + "字符编码\n" + model.wx_code, preferredStyle: .alert)
            
            let image = UIImage.init(named: model.imageName)
            let att = NSTextAttachment()
            att.image = image!
            
            alertC.setValue(NSAttributedString(attachment: att), forKey: "attributedTitle")
            
            let cancelAction = UIAlertAction(title: "确定", style: .cancel) { (_) in
                collectionView.deselectItem(at: indexPath, animated: true);
            }
            alertC.addAction(cancelAction)
            present(alertC, animated: true) {
            }
        } else {
            collectionView.deselectItem(at: indexPath, animated: true);
        }
    }
    
}

extension ViewController: UISearchControllerDelegate, UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        searchResults = dataSource.filter { return $0.name.lowercased().contains(searchController.searchBar.text?.lowercased() ?? "") || $0.wx_code.contains(searchController.searchBar.text ?? "") }
        collectionView.reloadData()
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        collectionView.reloadData()
    }
}

class CollectionViewCell: UICollectionViewCell {
    lazy var emojiImageView: UIImageView = {
        let emojiImageView = UIImageView()
        emojiImageView.translatesAutoresizingMaskIntoConstraints = false
        return emojiImageView
    }()
    lazy var emojiLabel: UILabel = {
        let emojiLabel = UILabel()
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        emojiLabel.adjustsFontSizeToFitWidth = true
        emojiLabel.textAlignment = .center
        return emojiLabel
    }()
    lazy var emojiCodeLabel: UILabel = {
        let emojiCodeLabel = UILabel()
        emojiCodeLabel.translatesAutoresizingMaskIntoConstraints = false
        emojiCodeLabel.adjustsFontSizeToFitWidth = true
        emojiCodeLabel.textAlignment = .center
        emojiCodeLabel.font = UIFont.systemFont(ofSize: 12)
        emojiCodeLabel.textColor = UIColor.lightGray
        return emojiCodeLabel
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(emojiImageView)
        contentView.addSubview(emojiLabel)
        contentView.addSubview(emojiCodeLabel)
        
        let views = ["iv": emojiImageView, "label": emojiLabel, "codeLabel": emojiCodeLabel]
        
        contentView.addConstraint(NSLayoutConstraint.init(item: emojiImageView, attribute: .centerX, relatedBy: .equal, toItem: contentView, attribute: .centerX, multiplier: 1, constant: 0))
        let vc0 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-5-[iv]", options: [], metrics: [:], views: views)
        contentView.addConstraints(vc0)
        
        let vc = NSLayoutConstraint.constraints(withVisualFormat: "V:[iv]-5-[label]", options: [], metrics: [:], views: views)
        contentView.addConstraints(vc)
        
        let hc = NSLayoutConstraint.constraints(withVisualFormat: "H:|-[label]-|", options: [], metrics: [:], views: views)
        contentView.addConstraints(hc)
        
        let vc1 = NSLayoutConstraint.constraints(withVisualFormat: "V:[label]-5-[codeLabel]-5-|", options: [], metrics: [:], views: views)
        contentView.addConstraints(vc1)
        
        let hc1 = NSLayoutConstraint.constraints(withVisualFormat: "H:|-[codeLabel]-|", options: [], metrics: [:], views: views)
        contentView.addConstraints(hc1)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                self.contentView.backgroundColor = UIColor.groupTableViewBackground
            } else {
                UIView.animate(withDuration: 2) {
                    self.contentView.backgroundColor = UIColor.white
                }
            }
        }
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        setNeedsLayout()
        layoutIfNeeded()
        let size = contentView.systemLayoutSizeFitting(layoutAttributes.size)
        var rect = layoutAttributes.frame
        rect.size.height = ceil(size.height)
        layoutAttributes.frame = rect
        return layoutAttributes
    }
    
}

struct Model {
    var name: String
    var zh_code: String
    var wx_code: String
    var imageName: String
    init(data: [String: String]) {
        name = data["name"] ?? "";
        zh_code = data["zh_code"] ?? "";
        wx_code = data["wx_code"] ?? "";
        imageName = data["imageName"] ?? "";
    }
}

class SettingViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    var copyAvaliable = UserDefaults.standard.bool(forKey: "CopyAvaliable") {
        didSet {
            UserDefaults.standard.set(copyAvaliable, forKey: "CopyAvaliable")
            UserDefaults.standard.synchronize()
        }
    }
    var copyWxCode = UserDefaults.standard.bool(forKey: "CopyWxCode") {
        didSet {
            UserDefaults.standard.set(copyWxCode, forKey: "CopyWxCode")
            UserDefaults.standard.synchronize()
        }
    }
    var showAlert = UserDefaults.standard.bool(forKey: "ShowAlert") {
        didSet {
            UserDefaults.standard.set(showAlert, forKey: "ShowAlert")
            UserDefaults.standard.synchronize()
        }
    }
    
}

extension SettingViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return copyAvaliable ? 3 : 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "点击是否展示弹窗？"
        case 1:
            return "点击是否复制表情编码？"
        default:
            return "复制中文编码还是字符编码？"
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if indexPath.section == 0 {
            cell.textLabel?.text = indexPath.row == 0 ? "是" : "否"
            if indexPath.row == 0 {
                cell.accessoryType = showAlert ? .checkmark : .none
            } else {
                cell.accessoryType = !showAlert ? .checkmark : .none
            }
        } else if indexPath.section == 1 {
            cell.textLabel?.text = indexPath.row == 0 ? "是" : "否"
            if indexPath.row == 0 {
                cell.accessoryType = copyAvaliable ? .checkmark : .none
            } else {
                cell.accessoryType = !copyAvaliable ? .checkmark : .none
            }
        } else if (indexPath.section == 2) {
            cell.textLabel?.text = indexPath.row == 0 ? "中文编码" : "字符编码"
            if indexPath.row == 0 {
                cell.accessoryType = !copyWxCode ? .checkmark : .none
            } else {
                cell.accessoryType = copyWxCode ? .checkmark : .none
            }
        }
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if indexPath.section == 0 {
            showAlert = indexPath.row == 0
        } else if indexPath.section == 1 {
            copyAvaliable = indexPath.row == 0
        } else if indexPath.section == 2 {
            copyWxCode = indexPath.row == 1
        }
        tableView.reloadData()
    }
}