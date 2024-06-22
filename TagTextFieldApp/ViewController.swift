//
//  ViewController.swift
//  TagTextFieldApp
//
//  Created by nakamori.emiri on 2024/06/22.
//

import UIKit

class ViewController: UIViewController, UITextViewDelegate {
    
    private let textView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.layer.borderColor = UIColor.gray.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 5
        return textView
    }()
    
    private let tagScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
    private let tagStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 10
        return stackView
    }()
    
    private var tags: [Tag] = [
        Tag(text: "嘔吐", color: .red),
        Tag(text: "うんち", color: .red),
        Tag(text: "ご飯", color: .orange),
        Tag(text: "薬", color: .orange),
        Tag(text: "発作", color: .red)
    ]
    
    private var insertedTags: [NSRange] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTagButtons()
    }
    
    private func setupUI() {
        view.addSubview(textView)
        view.addSubview(tagScrollView)
        tagScrollView.addSubview(tagStackView)
        
        textView.translatesAutoresizingMaskIntoConstraints = false
        tagScrollView.translatesAutoresizingMaskIntoConstraints = false
        tagStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textView.heightAnchor.constraint(equalToConstant: 200),
            
            tagScrollView.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 20),
            tagScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tagScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tagScrollView.heightAnchor.constraint(equalToConstant: 50),
            
            tagStackView.topAnchor.constraint(equalTo: tagScrollView.topAnchor),
            tagStackView.leadingAnchor.constraint(equalTo: tagScrollView.leadingAnchor, constant: 20),
            tagStackView.trailingAnchor.constraint(equalTo: tagScrollView.trailingAnchor, constant: -20),
            tagStackView.bottomAnchor.constraint(equalTo: tagScrollView.bottomAnchor)
        ])
        
        textView.delegate = self
    }
    
    private func setupTagButtons() {
        for tag in tags {
            let button = UIButton(type: .system)
            button.setTitle(tag.text, for: .normal)
            button.backgroundColor = tag.color
            button.setTitleColor(.white, for: .normal)
            button.layer.cornerRadius = 15
            button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
            button.addTarget(self, action: #selector(tagButtonTapped(_:)), for: .touchUpInside)
            tagStackView.addArrangedSubview(button)
        }
    }
    
    @objc private func tagButtonTapped(_ sender: UIButton) {
        guard let tagText = sender.titleLabel?.text else { return }
        insertTag(tagText)
    }
    
    private func insertTag(_ tagText: String) {
        let attributedString = NSMutableAttributedString(attributedString: textView.attributedText)
        let tag = tags.first { $0.text == tagText }
        
        let tagAttributes: [NSAttributedString.Key: Any] = [
            .backgroundColor: tag?.color ?? .clear,
            .font: UIFont.systemFont(ofSize: 16)
        ]
        
        let spaceAttributes: [NSAttributedString.Key: Any] = [
            .backgroundColor: UIColor.clear,
            .font: UIFont.systemFont(ofSize: 16)
        ]
        
        let insertionPoint = textView.selectedRange.location
        
        // 前の空白を挿入
        let frontSpaceString = NSAttributedString(string: " ", attributes: spaceAttributes)
        attributedString.insert(frontSpaceString, at: insertionPoint)
        
        // タグを挿入
        let tagAttributedString = NSAttributedString(string: tagText, attributes: tagAttributes)
        attributedString.insert(tagAttributedString, at: insertionPoint + 1)
        
        // 後ろの空白を挿入
        let backSpaceString = NSAttributedString(string: " ", attributes: spaceAttributes)
        attributedString.insert(backSpaceString, at: insertionPoint + tagText.count + 1)
        
        textView.attributedText = attributedString
        
        // タグの範囲を記録（空白を含む）
        insertedTags.append(NSRange(location: insertionPoint, length: tagText.count + 2))
        
        // カーソルを移動
        textView.selectedRange = NSRange(location: insertionPoint + tagText.count + 2, length: 0)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // キーボードのDeleteキーが押されたかどうかを確認
        if text == "" && range.length == 0 {
            // Deleteキーが押されており、かつ置換テキストが空文字の場合
            
            // 現在のカーソル位置を取得
            let cursorPosition = textView.selectedRange.location
            
            // 削除するタグの範囲を探す
            for tagRange in insertedTags {
                if cursorPosition == tagRange.location {
                    // カーソル位置がタグの開始位置と一致する場合、そのタグを削除
                    
                    // タグ全体（開始の空白、タグ、終端の空白）を削除
                    let deleteRange = NSRange(location: tagRange.location, length: tagRange.length + 1)
                    let attributedString = NSMutableAttributedString(attributedString: textView.attributedText)
                    attributedString.replaceCharacters(in: deleteRange, with: "")
                    textView.attributedText = attributedString
                    
                    // 更新後のタグ範囲を再計算
                    updateTagRanges()
                    
                    // カーソル位置を移動
                    textView.selectedRange = NSRange(location: deleteRange.location, length: 0)
                    
                    return false  // テキストの置換を行わない（タグを削除したので）
                }
            }
        }
        
        return true
    }

    
    func textViewDidChange(_ textView: UITextView) {
        updateTagRanges()
    }
    
    private func updateTagRanges() {
        insertedTags.removeAll()
        let fullRange = NSRange(location: 0, length: textView.text.count)
        textView.attributedText.enumerateAttribute(.backgroundColor, in: fullRange, options: []) { (value, range, _) in
            if value != nil, range.length > 2 {
                insertedTags.append(range)
            }
        }
    }
}

struct Tag {
    let text: String
    let color: UIColor
}

#if DEBUG
import SwiftUI

struct ViewControllerPreview: PreviewProvider {
    static var previews: some View {
        ViewControllerRepresentable()
            .edgesIgnoringSafeArea(.all)
    }
}

struct ViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ViewController {
        return ViewController()
    }
    
    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
    }
}
#endif
