package com.example.bdget.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.example.bdget.dto.StudentRequest;
import com.example.bdget.model.Student;
import com.example.bdget.service.StudentService;

import jakarta.validation.Valid;

// Sin CORS abierto: la API se consume a traves del gateway del mismo origen
@RestController
@RequestMapping("/students")
public class StudentController {
    private final StudentService studentService;

    public StudentController(StudentService studentService) {
        this.studentService = studentService;
    }

    @GetMapping
    public List<Student> getAllStudents(){
        return studentService.getAllStudents();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Student> getStudentById(@PathVariable Long id) {
        return studentService.getStudentById(id)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @GetMapping("/search")
    public List<Student> searchStudents(@RequestParam String name) {
        return studentService.searchStudentsByName(name);
    }

    @GetMapping("/count")
    public long countStudents() {
        return studentService.countTotalStudents();
    }

    // @Valid activa las reglas de Bean Validation definidas en el DTO StudentRequest
    @PostMapping
    public Student creaStudent(@Valid @RequestBody StudentRequest request) {
        return studentService.createStudent(request.toEntity());
    }

    @PutMapping("/{id}")
    public ResponseEntity<Student> updateStudent(@PathVariable Long id, @Valid @RequestBody StudentRequest request) {
        Student updated = studentService.updateStudent(id, request.toEntity());
        return updated != null ? ResponseEntity.ok(updated) : ResponseEntity.notFound().build();
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteStudent(@PathVariable Long id){
        if (studentService.getStudentById(id).isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        studentService.deleteStudent(id);
        return ResponseEntity.noContent().build();
    }
}
