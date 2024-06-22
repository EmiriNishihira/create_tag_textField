//
//  ViewController.swift
//  TagTextFieldApp
//
//  Created by nakamori.emiri on 2024/06/22.
//

import UIKit

class ViewController: UIViewController {
    // UITextFieldとUILabelの宣言
    let textField = UITextField(frame: CGRect(x: 20, y: 100, width: 300, height: 40))
    var selectedLabels = [UILabel]()
    var outsideLabels = [UILabel]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // UITextFieldの設定
        textField.borderStyle = .roundedRect
        view.addSubview(textField)

        // 初期のタグデータ
        let initialTags: [String] = ["Tag1", "Tag2", "Tag3", "Tag4", "Tag5"]

        // UILabelの設定（テキストフィールドの外に動的に配置）
        let labelHeight = 40
        let labelPadding = 2 // タグの間隔
        var currentX = 20 // X座標の初期値

        for tagText in initialTags {
            let labelWidth = tagText.size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17.0)]).width + 20
            let outsideLabel = UILabel(frame: CGRect(x: currentX, y: 150, width: Int(labelWidth), height: labelHeight))
            outsideLabel.text = tagText
            outsideLabel.textAlignment = .center
            outsideLabel.backgroundColor = .orange
            outsideLabel.textColor = .black
            outsideLabel.layer.cornerRadius = 5
            outsideLabel.layer.masksToBounds = true
            outsideLabel.isUserInteractionEnabled = true
            view.addSubview(outsideLabel)

            // タップジェスチャーの追加
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(labelTapped(_:)))
            outsideLabel.addGestureRecognizer(tapGesture)

            outsideLabels.append(outsideLabel)

            // X座標を更新して次のタグを配置する
            currentX += Int(labelWidth) + labelPadding
        }
    }

    @objc func labelTapped(_ gesture: UITapGestureRecognizer) {
        guard let tappedLabel = gesture.view as? UILabel else { return }

        // すでに選択されているラベルかどうかを判定
        if selectedLabels.contains(tappedLabel) {
            // すでに選択されている場合は何もしない
            return
        }

        // 選択されたラベルをUITextField内に追加
        let labelWidth = tappedLabel.frame.width
        let labelHeight = tappedLabel.frame.height

        if let lastLabel = selectedLabels.last {
            // 最後に選択されたラベルの右隣に配置する
            let newX = lastLabel.frame.origin.x + lastLabel.frame.width + 2
            tappedLabel.frame = CGRect(x: newX, y: 0, width: labelWidth, height: labelHeight)
        } else {
            // 初めて選択される場合は左端に配置する
            tappedLabel.frame = CGRect(x: 0, y: 0, width: labelWidth, height: labelHeight)
        }

        // 選択されたラベルを追加して表示
        selectedLabels.append(tappedLabel)
        updateTextFieldLeftView()
    }

    // UITextFieldの左側に選択されたタグを表示する
    func updateTextFieldLeftView() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 2
        stackView.alignment = .center
        stackView.distribution = .fill

        for label in selectedLabels {
            stackView.addArrangedSubview(label)
        }

        textField.leftView = stackView
        textField.leftViewMode = .always
    }
}

