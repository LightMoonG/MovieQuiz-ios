//
//  QuestionFactory.swift
//  MovieQuiz
//
//  Created by Глеб Хамин on 09.10.2023.
//

import Foundation

final class QuestionFactoryImpl {
    
    //MARK: - Properties
    
    private let moviesLoader: MoviesLoading
    private weak var delegate: QuestionFactoryDelegate?
    private var movies: [MostPopularMovie] = []
    
    //MARK: - Init
    
    init(moviesLoader: MoviesLoading, delegate: QuestionFactoryDelegate?) {
        self.moviesLoader = moviesLoader
        self.delegate = delegate
    }
}

extension QuestionFactoryImpl: QuestionFactory {
    
    //MARK: - Public Methods
    
    func loadData() {
        moviesLoader.loadMovies { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let mostPopularMovies):
                    self.movies = mostPopularMovies.docs
                    self.delegate?.didLoadDataFromServer()
                case .failure(let error):
                    self.delegate?.didFailToLoadData(with: error)
                }
            }
        }
    }
    
    func requestNextQuestion() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            let index = (0..<self.movies.count).randomElement() ?? 0
            
            guard let movie = self.movies[safe: index] else { return }
            
            var imageData = Data()
           
           do {
               imageData = try Data(contentsOf: movie.poster.url)
            } catch {
                print("Failed to load image")
            }
            
            let rating = Float(movie.rating.kp)

            let text = "Рейтинг этого фильма больше чем 7?"
            let correctAnswer = rating > 7
            
            let question = QuizQuestion(image: imageData,
                                         text: text,
                                         correctAnswer: correctAnswer)
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.didReceiveNextQuestion(question)
            }
        }
    }
}
