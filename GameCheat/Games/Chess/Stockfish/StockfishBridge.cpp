#include "StockfishBridge.h"

#include <algorithm>
#include <chrono>
#include <condition_variable>
#include <cstring>
#include <memory>
#include <mutex>
#include <optional>
#include <sstream>
#include <string>
#include <string_view>

#include "bitboard.h"
#include "engine.h"
#include "misc.h"
#include "position.h"
#include "search.h"
#include "tune.h"

namespace {

std::once_flag initFlag;
std::mutex engineMutex;
std::unique_ptr<Stockfish::Engine> engine;
bool initSucceeded = false;

void set_option(Stockfish::OptionsMap& options, std::string_view name, std::string_view value) {
    std::istringstream command("name " + std::string(name) + " value " + std::string(value));
    options.setoption(command);
}

void initialize_engine() {
    try
    {
        Stockfish::Bitboards::init();
        Stockfish::Position::init();

        engine = std::make_unique<Stockfish::Engine>(std::nullopt);
        Stockfish::Tune::init(engine->get_options());

        // Mobile defaults: single thread and modest hash keep CPU/battery in check.
        auto& options = engine->get_options();
        set_option(options, "Threads", "1");
        set_option(options, "Hash", "32");

        engine->set_on_update_no_moves([](const Stockfish::Engine::InfoShort&) {});
        engine->set_on_update_full([](const Stockfish::Engine::InfoFull&) {});
        engine->set_on_iter([](const Stockfish::Engine::InfoIter&) {});
        engine->set_on_bestmove([](std::string_view, std::string_view) {});
        engine->set_on_verify_networks([](std::string_view) {});

        initSucceeded = true;
    }
    catch (...)
    {
        engine.reset();
        initSucceeded = false;
    }
}

}  // namespace

extern "C" int gc_stockfish_bestmove(const char* fen,
                                     int32_t     skill_level,
                                     int32_t     move_time_ms,
                                     char*       out_move,
                                     int32_t     out_move_capacity) {
    if (!fen || !out_move || out_move_capacity <= 1)
    {
        return 0;
    }

    std::call_once(initFlag, initialize_engine);
    if (!initSucceeded || !engine)
    {
        return 0;
    }

    const auto clampedSkill    = std::clamp<int32_t>(skill_level, 0, 20);
    const auto clampedMoveTime = std::max<int32_t>(move_time_ms, 25);
    std::string bestMove;

    std::lock_guard<std::mutex> lock(engineMutex);

    engine->wait_for_search_finished();
    auto& options = engine->get_options();
    set_option(options, "Skill Level", std::to_string(clampedSkill));

    std::mutex              doneMutex;
    std::condition_variable doneCv;
    bool                    done = false;

    engine->set_on_bestmove([&](std::string_view move, std::string_view) {
        {
            std::lock_guard<std::mutex> doneLock(doneMutex);
            bestMove = std::string(move);
            done     = true;
        }
        doneCv.notify_one();
    });

    Stockfish::Search::LimitsType limits;
    limits.startTime = Stockfish::now();
    limits.movetime  = clampedMoveTime;

    engine->set_position(std::string(fen), {});
    engine->go(limits);

    std::unique_lock<std::mutex> waitLock(doneMutex);
    doneCv.wait_for(waitLock, std::chrono::milliseconds(clampedMoveTime + 500), [&] { return done; });
    waitLock.unlock();

    engine->stop();
    engine->wait_for_search_finished();
    engine->set_on_bestmove([](std::string_view, std::string_view) {});

    if (!done || bestMove.empty() || bestMove == "(none)")
    {
        return 0;
    }

    if (static_cast<int32_t>(bestMove.size()) + 1 > out_move_capacity)
    {
        return 0;
    }

    std::memcpy(out_move, bestMove.c_str(), bestMove.size() + 1);
    return 1;
}
