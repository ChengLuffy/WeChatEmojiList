//
//  ViewController.swift
//  WeChatEmoji
//
//  Created by 成殿 on 2019/7/3.
//  Copyright © 2019 成殿. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

//    @IBOutlet weak var collectionView: UICollectionView!
    lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.estimatedItemSize = CGSize(width: 65, height: 100)
        let view = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        view.delegate = self
        view.dataSource = self
        view.register(CollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        view.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.keyboardDismissMode = UIScrollView.KeyboardDismissMode.onDrag
        return view
    }()
    
    /// 点击是否可以复制
    lazy var copyAvaliable: Bool = {
        var copyAvaliable = UserDefaults.standard.bool(forKey: "CopyAvaliable")
        return copyAvaliable
    }()
    
    /// 是否复制 字符编码？否 则复制中文编码
    lazy var copyWxCode: Bool = {
        var copyWxCode = UserDefaults.standard.bool(forKey: "CopyWxCode")
        return copyWxCode
    }()
    
    /// 是否弹出提示信息
    lazy var showAlert: Bool = {
        var showAlert = UserDefaults.standard.bool(forKey: "ShowAlert")
        return showAlert
    }()
    
    /// 数据源
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
    
    /// 搜索结果
    var searchResults: [Model] = [Model]()
    
    /// 搜索视图控制器
    lazy var searchC: UISearchController = {
        weak var weakSelf = self
        let searchC = UISearchController(searchResultsController: nil)
        searchC.searchResultsUpdater = self
        searchC.delegate = self
        searchC.obscuresBackgroundDuringPresentation = false;
        searchC.searchBar.placeholder = "请输入你想搜索的表情关键词"
        searchC.searchBar.autocapitalizationType = .none
        // 设定 搜索控制器 弹出时，导航栏不消失
        searchC.hidesNavigationBarDuringPresentation = false
        return searchC
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
//        // 注册 cell
//        collectionView.register(CollectionViewCell.self, forCellWithReuseIdentifier: "cell")
//        // 设定 预估大小，此处只有宽有真是用途
//        (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).estimatedItemSize = CGSize.init(width: 65, height: 100)
        
        view.addSubview(collectionView)
        
        let views = ["collectionView": collectionView]
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[collectionView]-0-|", options: [], metrics: [:], views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[collectionView]-0-|", options: [], metrics: [:], views: views))
        
        title = "微信表情"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "设置", style: .done, target: self, action: #selector(settingBBIAction))
        
        // 设定 搜索控制器
        navigationItem.searchController = searchC
        // 设定 搜索控制器滑动时隐藏
        navigationItem.hidesSearchBarWhenScrolling = true
        // 设置 导航栏大标题
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
        // 监听 用户配置信息变化
        NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: UserDefaults.standard, queue: OperationQueue.main) { (noti) in
            let center = noti.object as! UserDefaults
            self.copyWxCode = center.bool(forKey: "CopyWxCode")
            self.copyAvaliable = center.bool(forKey: "CopyAvaliable")
            self.showAlert = center.bool(forKey: "ShowAlert")
        }
        
    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "SettingPopover" {
//            let popoverVC = segue.destination
//            popoverVC.popoverPresentationController?.delegate = self
//        }
//    }
    
    /// MARK: Actions
    @objc func settingBBIAction() {
        let settingVC = SettingViewController()
        /**
        let nav = UINavigationController(rootViewController: settingVC)
        nav.modalPresentationStyle = .popover
        nav.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        nav.preferredContentSize = CGSize(width: view.frame.size.width*0.66, height: view.frame.size.height*0.66)
        nav.isModalInPopover = true
        nav.popoverPresentationController?.delegate = self
        
        let vc = searchC.isActive ? searchC : navigationController
        
        vc?.present(nav, animated: true, completion: nil)
         */
        
//        let nav = UINavigationController(rootViewController: settingVC)
        settingVC.modalPresentationStyle = .popover
        settingVC.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        settingVC.preferredContentSize = CGSize(width: view.frame.size.width*0.66, height: view.frame.size.height*0.66)
        settingVC.isModalInPopover = true
        settingVC.popoverPresentationController?.delegate = self
        settingVC.popoverPresentationController?.passthroughViews = [view]
        
        let vc = searchC.isActive ? searchC : navigationController
        
        vc?.present(settingVC, animated: true, completion: {
            self.collectionView.isUserInteractionEnabled = false
        })
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if collectionView.isUserInteractionEnabled == false {
            let vc = searchC.isActive ? searchC : navigationController
            vc?.presentedViewController?.dismiss(animated: true, completion: {
                self.collectionView.isUserInteractionEnabled = true
            })
        }
    }
    
    /// MARK: UIScrollViewDelegate
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        scrollView.setContentOffset(CGPoint.zero, animated: true)
        return false
    }
}

extension ViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // 当 搜索控制器 活跃时 显示的是 搜索结果
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
        // 决定是否 复制
        if copyAvaliable {
            UIPasteboard.general.string = copyWxCode ? model.wx_code : model.zh_code
        }
        // 决定是否弹窗提示
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
            if searchC.isActive {
                searchC.present(alertC, animated: true) {
                }
            } else {
                present(alertC, animated: true) {
                }
            }
        } else {
            collectionView.deselectItem(at: indexPath, animated: true);
        }
    }
    
}

extension ViewController: UISearchControllerDelegate, UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        // 搜索框 文字更新时 根据输入的文字 查询结果
        searchResults = dataSource.filter { return $0.name.lowercased().contains(searchController.searchBar.text?.lowercased() ?? "") || $0.wx_code.lowercased().contains(searchController.searchBar.text?.lowercased() ?? "") || $0.zh_code.lowercased().contains(searchController.searchBar.text?.lowercased() ?? "") }
        collectionView.reloadData()
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        collectionView.reloadData()
    }
}

/// 单元视图
class CollectionViewCell: UICollectionViewCell {
    /// 图片视图
    lazy var emojiImageView: UIImageView = {
        let emojiImageView = UIImageView()
        emojiImageView.translatesAutoresizingMaskIntoConstraints = false
        return emojiImageView
    }()
    /// 中文描述文本
    lazy var emojiLabel: UILabel = {
        let emojiLabel = UILabel()
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        emojiLabel.adjustsFontSizeToFitWidth = true
        emojiLabel.textAlignment = .center
        return emojiLabel
    }()
    /// 字符描述文本
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
        // 视图添加 约束添加
        contentView.addSubview(emojiImageView)
        contentView.addSubview(emojiLabel)
        contentView.addSubview(emojiCodeLabel)
        
        let views = ["iv": emojiImageView, "label": emojiLabel, "codeLabel": emojiCodeLabel]
        
        contentView.addConstraint(NSLayoutConstraint.init(item: emojiImageView, attribute: .centerX, relatedBy: .equal, toItem: contentView, attribute: .centerX, multiplier: 1, constant: 0))
        let vc0 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-5-[iv]", options: [], metrics: [:], views: views)
        contentView.addConstraints(vc0)
        
        let vc = NSLayoutConstraint.constraints(withVisualFormat: "V:[iv]-5-[label]", options: [], metrics: [:], views: views)
        contentView.addConstraints(vc)
        
        let hc = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[label]-0-|", options: [], metrics: [:], views: views)
        contentView.addConstraints(hc)
        
        let vc1 = NSLayoutConstraint.constraints(withVisualFormat: "V:[label]-5-[codeLabel]-5-|", options: [], metrics: [:], views: views)
        contentView.addConstraints(vc1)
        
        let hc1 = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[codeLabel]-0-|", options: [], metrics: [:], views: views)
        contentView.addConstraints(hc1)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 点击效果
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
    
    /// 自适应高度
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

/// 模型
struct Model {
    /// 表情名称
    var name: String
    /// 表情的中文字符编码
    var zh_code: String
    /// 表情的 字符编码
    var wx_code: String
    /// 表情的图片名称
    var imageName: String
    /// 初始化模型
    ///
    /// - Parameter data: json 数据
    init(data: [String: String]) {
        name = data["name"] ?? "";
        zh_code = data["zh_code"] ?? "";
        wx_code = data["wx_code"] ?? "";
        imageName = data["imageName"] ?? "";
    }
}

/// 设置页
class SettingViewController: UIViewController {
//    @IBOutlet weak var tableView: UITableView!
    lazy var tableView: UITableView = {
        let view = UITableView(frame: CGRect.zero, style: .grouped)
        view.delegate = self
        view.dataSource = self
        view.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// 是否可以点击复制
    var copyAvaliable = UserDefaults.standard.bool(forKey: "CopyAvaliable") {
        didSet {
            // 赋新值时存储并同步
            UserDefaults.standard.set(copyAvaliable, forKey: "CopyAvaliable")
            UserDefaults.standard.synchronize()
        }
    }
    /// 是否复制 字符编码？否 则复制中文编码
    var copyWxCode = UserDefaults.standard.bool(forKey: "CopyWxCode") {
        didSet {
            UserDefaults.standard.set(copyWxCode, forKey: "CopyWxCode")
            UserDefaults.standard.synchronize()
        }
    }
    /// 是否弹出提示信息
    var showAlert = UserDefaults.standard.bool(forKey: "ShowAlert") {
        didSet {
            UserDefaults.standard.set(showAlert, forKey: "ShowAlert")
            UserDefaults.standard.synchronize()
        }
    }
    
    @objc func doneAction(_ sender: Any) {
        dismiss(animated: true) {
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        let views = ["tableView": tableView]
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[tableView]-0-|", options: [], metrics: [:], views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[tableView]-0-|", options: [], metrics: [:], views: views))
        
//        title = "设置"
//        
//        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "完成", style: .plain, target: self, action: #selector(doneAction(_:)))
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
