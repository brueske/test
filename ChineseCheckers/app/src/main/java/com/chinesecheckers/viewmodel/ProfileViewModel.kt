package com.chinesecheckers.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.chinesecheckers.data.entities.Profile
import com.chinesecheckers.data.repository.AppRepository
import kotlinx.coroutines.launch

class ProfileViewModel(private val repository: AppRepository) : ViewModel() {

    fun save(profile: Profile) = viewModelScope.launch {
        if (profile.id == 0L) repository.insertProfile(profile)
        else repository.updateProfile(profile)
    }

    fun delete(profile: Profile) = viewModelScope.launch {
        repository.deleteProfile(profile)
    }

    class Factory(private val repository: AppRepository) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T =
            ProfileViewModel(repository) as T
    }
}
