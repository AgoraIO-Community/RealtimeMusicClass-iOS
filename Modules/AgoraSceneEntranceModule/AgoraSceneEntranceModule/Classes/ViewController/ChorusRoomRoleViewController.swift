//
//  ChorusRoomRoleViewController.swift
//  AgoraSceneEntranceModule
//
//  Created by Jonathan on 2022/2/10.
//

import UIKit
import AgoraViewKit

class ChorusRoomRoleViewController: UIViewController {
    
    private var rolesView: UIStackView!
    
    private var teacherView: RoleSelectView!
    
    private var studentView: RoleSelectView!
    
    private var audienceView: RoleSelectView!
    
    private var nameInputView: InfoInputView!
    
    private var nextButton: GradientButton!
    
    private var entranceModel: ClassEntranceModel
    
    init(entranceModel: ClassEntranceModel) {
        self.entranceModel = entranceModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "设置上课身份"
        self.view.backgroundColor = .white
        
        self.createViews()
        self.createConstrains()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.nameInputView.textField.becomeFirstResponder()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        self.nameInputView.textField.resignFirstResponder()
    }
    
    @objc func onClickNext(_ sender: UIButton) {
        guard let name = self.nameInputView.textField.text?.trimmingCharacters(in: .whitespaces), name.count != 0 else {
            AgoraToast.toast(msg: "请输入昵称")
            return
        }
        guard name.count <= 20 else {
            AgoraToast.toast(msg: "昵称长度不能超过20个字符")
            return
        }
        let regexChar = "[a-zA-Z0-9]*$"
        let predChar = NSPredicate.init(format: "SELF MATCHES %@", regexChar)
        guard predChar.evaluate(with: name) else {
            AgoraToast.toast(msg: "请使用字母和数字组合")
            return
        }
        self.entranceModel.userName = name
        let vc = ChorusRoomListViewController(entranceModel: self.entranceModel)
        self.navigationController?.pushViewController(vc, completion: nil)
    }
    
    @objc func onClickTeacher(_ sender: UIButton) {
        entranceModel.role = .owner
        teacherView.isSelected = true
        studentView.isSelected = false
        audienceView.isSelected = false
    }
    
    @objc func onClickStudnet(_ sender: UIButton) {
        entranceModel.role = .coHost
        teacherView.isSelected = false
        studentView.isSelected = true
        audienceView.isSelected = false
    }
    
    @objc func onClickAudience(_ sender: UIButton) {
        entranceModel.role = .audience
        teacherView.isSelected = false
        studentView.isSelected = false
        audienceView.isSelected = true
    }
}
// MARK: - UITextFieldDelegate
extension ChorusRoomRoleViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
// MARK: - Creations
private extension ChorusRoomRoleViewController {
    func createViews() {
        rolesView = UIStackView()
        rolesView.backgroundColor = .clear
        rolesView.axis = .horizontal
        rolesView.spacing = 2
        rolesView.distribution = .equalSpacing
        rolesView.alignment = .fill
        view.addSubview(rolesView)
        
        teacherView = RoleSelectView(frame: CGRect(x: 0, y: 0, width: 80, height: 126))
        teacherView.label.text = "教师"
        teacherView.setImage(UIImage.rmc_named("ic_role_teacher_unsel"),
                             selectedImage: UIImage.rmc_named("ic_role_teacher_sel"))
        teacherView.isSelected = true
        teacherView.button.addTarget(self, action: #selector(onClickTeacher(_:)), for: .touchUpInside)
        self.rolesView.addArrangedSubview(teacherView)
        
        studentView = RoleSelectView(frame: CGRect(x: 0, y: 0, width: 80, height: 126))
        studentView.label.text = "学生"
        studentView.setImage(UIImage.rmc_named("ic_role_student_unsel"),
                             selectedImage: UIImage.rmc_named("ic_role_student_sel"))
        studentView.isSelected = false
        studentView.button.addTarget(self, action: #selector(onClickStudnet(_:)), for: .touchUpInside)
        self.rolesView.addArrangedSubview(studentView)
        
        audienceView = RoleSelectView(frame: CGRect(x: 0, y: 0, width: 80, height: 126))
        audienceView.label.text = "观众"
        audienceView.setImage(UIImage.rmc_named("ic_role_student_unsel"),
                              selectedImage: UIImage.rmc_named("ic_role_student_sel"))
        audienceView.isSelected = false
        audienceView.button.addTarget(self, action: #selector(onClickAudience(_:)), for: .touchUpInside)
        self.rolesView.addArrangedSubview(audienceView)
        
        nameInputView = InfoInputView()
        nameInputView.textField.placeholder = "请输入字母和数字昵称"
        nameInputView.textField.keyboardType = .asciiCapable
        nameInputView.textField.delegate = self
        nameInputView.label.text = "昵称"
        self.view.addSubview(nameInputView)
        
        nextButton = GradientButton(type: .system)
        nextButton.cornerRadius = 22
        nextButton.setGradient(from: UIColor(hex: 0x641BDF), to: UIColor(hex: 0xD07AF5))
        nextButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.addTarget(self, action: #selector(onClickNext(_:)), for: .touchUpInside)
        nextButton.setTitle("开始上课", for: .normal)
        nextButton.backgroundColor = UIColor(hex: 0x641BDF)
        self.view.addSubview(nextButton)
    }
    
    func createConstrains() {
        rolesView.snp.makeConstraints { make in
            make.top.equalTo(50)
            make.centerX.equalToSuperview()
            make.width.equalTo(280)
            make.height.equalTo(126)
        }
        nameInputView.snp.makeConstraints { make in
            make.top.equalTo(rolesView.snp.bottom).offset(50)
            make.width.equalTo(280)
            make.height.equalTo(40)
            make.centerX.equalToSuperview()
        }
        nextButton.snp.makeConstraints { make in
            make.width.equalTo(280)
            make.height.equalTo(44)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(-50)
        }
    }
}
