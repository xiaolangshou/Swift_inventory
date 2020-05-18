//
//  CatgoryVC.swift
//  WeeLinkPro1
//
//  Created by Liu Tao on 2020/5/14.
//  Copyright © 2020 Liu Tao. All rights reserved.
//

import UIKit

class CategoryVC: UIViewController {

    static let shared = CategoryVC()
    
    var leftData = [1,1,1,1]
    var rightData = [2,2,2,2,2,2]
    
    let searchBar = SearchBar()
    let leftView = UITableView()
    let rightView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupSearchBar()
        setupSideView()
    }
    
    func setupSearchBar() {
        
        view.addSubview(searchBar)
        searchBar.snp.makeConstraints { (make) in
            make.top.equalTo(90)
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        searchBar.placeholder = "搜索内容"
        searchBar.delegate = self
        searchBar.cancelBtnTap = { [weak self] in
            self?.searchBar.delegate?.searchBarCancelButtonClicked?(self!.searchBar)
        }
    }
    
    func setupSideView() {
        
        leftView.backgroundColor = UIColor.cyan
        leftView.delegate = self
        leftView.dataSource = self
        view.addSubview(leftView)
        leftView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.top.equalTo(searchBar.snp.bottom)
            make.bottom.equalToSuperview()
            make.width.equalTo(120)
        }
        leftView.tag = 0
        leftView.register(LeftTableViewCell.self, forCellReuseIdentifier: "CELL")
        
        rightView.backgroundColor = UIColor.green
        rightView.delegate = self
        rightView.dataSource = self
        view.addSubview(rightView)
        rightView.snp.makeConstraints { (make) in
            make.left.equalTo(leftView.snp.right)
            make.right.equalToSuperview()
            make.top.equalTo(searchBar.snp.bottom)
            make.bottom.equalToSuperview()
        }
        rightView.tag = 1
        rightView.register(RightTableViewCell.self, forCellReuseIdentifier: "CELL2")
    }
}

extension CategoryVC: UISearchBarDelegate {
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchBar.cancelBtn.isHidden = false
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.searchBar.cancelBtn.isHidden = true
    }
}

extension CategoryVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView.tag == 0 {
            return leftData.count
        } else if tableView.tag == 1 {
            return rightData.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView.tag == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CELL", for: indexPath) as! LeftTableViewCell
            cell.titleLbl.text = "\(leftData[indexPath.row])"
            
            return cell
        } else if tableView.tag == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CELL2", for: indexPath) as! RightTableViewCell
            cell.numLbl.text = "\(rightData[indexPath.row])"
            
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
}