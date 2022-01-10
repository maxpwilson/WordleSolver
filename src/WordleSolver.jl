module WordleSolver


function manual_solve(total_tries)
    sorted = load_presorted_dict()
    sort!(sorted, by=x->x[6], rev=true)
    tries = 1
    while true
        if length(sorted) == 0
            println("No more words left...")
            break
        end
        if tries == total_tries
            println("Failed, too many tries")
            break
        end
        nextup = sort(sorted, by=x->x[6])[1][1]
        nextup_total = sort(sorted, by=x->x[4])[1][1]
        nextup_positional = sort(sorted, by=x->x[5])[1][1]
        println("Best guess: $nextup")
        print("Guess: ")
        g = readline()
        filter!(i->i[1] != g, sorted)
        print("Result: ")
        r = readline()
        if r == "=====" || r == "y"
            println("Success in $(tries)!")
            break
        elseif r =="n"
            println("Word Not Found")
        else
            if length(replace(r, r"[^-+=]"=>"")) != 5
                println("Bad Input")
                push!(sorted, nextup)
                continue
            end
            println("Filtering words...")
            words = filter_words(g, r, sorted)
            freqs = get_frequencies(words)
            sorted = sort_words(words, freqs)
        end
        tries += 1
    end
    
end
function load_dict()
    words = []
    open("raw_dict_5.txt", "r") do r
        while !eof(r)
            word = readline(r)
            (length(word) == 5) && (push!(words, word))
        end
    end
    words
end
function load_presorted_dict()
    sorted = []
    open("pre_sorted.txt", "r") do r
        while !eof(r)
            line = readline(r)
            info = split(line, ",")
            push!(sorted, (replace(info[1], r"\(|\""=>""), parse(Float64, info[2]), parse(Float64, info[3]), parse(Int, info[4]), parse(Int, info[5]), parse(Float64, replace(info[6], ")"=>"")))) 
        end
    end
    sorted
end
function filter_words(guess, result, sorted)
    words = [i[1] for i in sorted]
    e = Dict()
    for i in 1:5
        if result[i] == '='
            if !(guess[i] in keys(e))
                e[guess[i]] = [i]
            else
                push!(e[guess[i]], i)
            end
        end
    end
    for j in 1:5
        letter = guess[j]
        if result[j] == '-'
            if letter in keys(e)
                for k in 1:5
                    if !(k in e[letter])
                        filter!(i->i[k] != letter, words)
                    end
                end
            else
                filter!(i->!occursin(letter, i), words)
            end
        elseif result[j] == '+'
            filter!(i->occursin(letter, i), words)
            filter!(i->i[j] != letter, words)
        elseif result[j] == '='
            filter!(i->i[j] == letter, words)
        end
    end
    words
end

function get_frequencies(words)
    freqs = Dict()
    alphabet = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z']
    for i in 1:5
        totals = Dict([letter => 0 for letter in alphabet])
        for word in words
            totals[word[i]] += 1
        end
        freq = Dict([letter => totals[letter] / length(words) for letter in alphabet])
        freqs[i] = freq
    end
    freqs["total"] = Dict([letter => sum([freqs[i][letter] for i in 1:5]) for letter in alphabet])
    freqs
end
function score_total(word, freqs)
    score = 0
    used_letters = []
    for letter in word
        (!(letter in used_letters)) && (score += freqs["total"][letter])
        push!(used_letters, letter)
    end
    score
end
function score_positional(word, freqs)
    score = 0
    for (i, letter) in enumerate(word)
        score += freqs[i][letter]
    end
    score
end
function score_words(words, freqs)
    scored = [(word, score_total(word, freqs), score_positional(word, freqs)) for word in words]
end
function rank_total(word, scored_words)
    for (idx, word_info) in enumerate(sort(scored_words; by=x->x[2], rev=true))
        ((word_info[1]) == word) && (return idx)
    end
end
function rank_positional(word, scored_words)
    for (idx, word_info) in enumerate(sort(scored_words; by=x->x[3], rev=true))
        ((word_info[1]) == word) && (return idx)
    end
end
function rank_average(word, scored_words)
    (rank_total(word, scored_words) + rank_positional(word, scored_words)) / 2
end
function sort_words(words, freqs)
    scored = score_words(words, freqs)
    sorted = [(info[1], info[2], info[3], rank_total(info[1], scored), rank_positional(info[1], scored), rank_average(info[1], scored)) for info in scored]
    sort(sorted, by=x->x[6])
end

export manual_solve

end # module
